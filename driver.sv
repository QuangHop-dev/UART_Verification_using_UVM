class driver extends uvm_driver#(UART_sequence_item);
  `uvm_component_utils(driver)

  virtual UART_interface intf;
  UART_sequence_item     item;

  // ---- runtime knobs (no extra cfg file needed) ----
  int unsigned rd_timeout_cycles = 20000;   // wait rx_empty->0
  int unsigned wr_timeout_cycles = 20000;   // wait tx_full->0
  bit          timeout_is_fatal  = 1'b1;    // default: fatal on timeout
  logic [9:0]  default_divsr     = 10'd54;  // default baud divider

  function new(string name = "driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual UART_interface)::get(this, "*", "intf", intf)) begin
      `uvm_error(get_type_name(), "virtual interface not set for driver")
    end

    // Plusargs overrides (optional)
    void'($value$plusargs("RD_TO=%d",   rd_timeout_cycles));
    void'($value$plusargs("WR_TO=%d",   wr_timeout_cycles));
    begin
      int tmp;
      if ($value$plusargs("DEF_DIVSR=%d", tmp))
        default_divsr = tmp[9:0];
    end

    if ($test$plusargs("TIMEOUT_NOT_FATAL"))
      timeout_is_fatal = 1'b0;
  endfunction

  // Wait N clock cycles (posedge)
  task automatic wait_cycles(int unsigned n);
    repeat (n) @(intf.drv_cb);
  endtask

  // UART bit time = 16 ticks; tick period = (divsr+1) cycles
  task automatic wait_bit_time();
    int unsigned cycles;
    cycles = (intf.mon_cb.divsr + 1) * 16;
    repeat (cycles) @(intf.drv_cb);
  endtask

  task automatic timeout_bail(string what, int unsigned limit);
    if (timeout_is_fatal)
      `uvm_fatal(get_type_name(),
        $sformatf("TIMEOUT waiting for %s after %0d cycles", what, limit))
    else
      `uvm_error(get_type_name(),
        $sformatf("TIMEOUT waiting for %s after %0d cycles", what, limit))
  endtask

  task automatic wait_tx_not_full();
    for (int unsigned c = 0; c < wr_timeout_cycles; c++) begin
      if (intf.mon_cb.tx_full === 1'b0) return;
      @(intf.drv_cb);
    end
    timeout_bail("tx_full==0", wr_timeout_cycles);
  endtask

  task automatic wait_rx_not_empty();
    for (int unsigned c = 0; c < rd_timeout_cycles; c++) begin
      if (intf.mon_cb.rx_empty === 1'b0) return;
      @(intf.drv_cb);
    end
    timeout_bail("rx_empty==0", rd_timeout_cycles);
  endtask

  task automatic apply_reset();
    intf.drv_cb.wr_uart <= 1'b0;
    intf.drv_cb.rd_uart <= 1'b0;
    intf.drv_cb.rx      <= 1'b1;
    intf.drv_cb.Reset   <= 1'b1;
    wait_cycles(5);
    intf.drv_cb.Reset   <= 1'b0;
    wait_cycles(2);
  endtask

  task automatic drive_rx_frame(byte data, bit bad_parity, bit bad_stop);
    bit parity;
    parity = ^data;                 // XOR parity
    if (bad_parity) parity = ~parity;

    // idle
    intf.drv_cb.rx <= 1'b1;
    wait_bit_time();

    // start bit
    intf.drv_cb.rx <= 1'b0;
    wait_bit_time();

    // data bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      intf.drv_cb.rx <= data[i];
      wait_bit_time();
    end

    // parity bit
    intf.drv_cb.rx <= parity;
    wait_bit_time();

    // stop bit
    intf.drv_cb.rx <= (bad_stop ? 1'b0 : 1'b1);
    wait_bit_time();

    // return to idle
    intf.drv_cb.rx <= 1'b1;
    wait_bit_time();
  endtask

  task automatic do_write_push(byte data);
    // wait until DUT can accept
    wait_tx_not_full();

    intf.drv_cb.w_data  <= data;
    intf.drv_cb.wr_uart <= 1'b1;
    @(intf.drv_cb);
    intf.drv_cb.wr_uart <= 1'b0;
    @(intf.drv_cb);
  endtask

  task automatic do_read_pop(int unsigned delay_cycles);
    // wait until RX has data
    wait_rx_not_empty();
    wait_cycles(delay_cycles);

    intf.drv_cb.rd_uart <= 1'b1;
    @(intf.drv_cb);
    intf.drv_cb.rd_uart <= 1'b0;
    @(intf.drv_cb);
  endtask

  task automatic drive_item(UART_sequence_item t);
    // optional divsr override
    if (t.set_divsr) begin
      intf.drv_cb.divsr <= t.divsr;
      @(intf.drv_cb); // let divsr settle for timing calculations
    end

    // Apply reset if requested
    if (t.kind == UART_sequence_item::TR_RESET || t.Reset) begin
      apply_reset();
      return;
    end

    // external RX injection
    if (t.inject_rx_frame) begin
      drive_rx_frame(t.w_data, t.bad_parity, t.bad_stop);
      if (t.do_read) do_read_pop(t.read_delay_cycles);
      return;
    end

    // normal path
    if (t.do_write) do_write_push(t.w_data);
    if (t.do_read)  do_read_pop(t.read_delay_cycles);
  endtask

  task run_phase(uvm_phase phase);
    // set safe defaults
    intf.drv_cb.wr_uart <= 1'b0;
    intf.drv_cb.rd_uart <= 1'b0;
    intf.drv_cb.rx      <= 1'b1;
    intf.drv_cb.Reset   <= 1'b0;
    intf.drv_cb.divsr   <= default_divsr;
    intf.drv_cb.w_data  <= 8'h00;
    @(intf.drv_cb);

    forever begin
      seq_item_port.get_next_item(item);
      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

endclass

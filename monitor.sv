class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  virtual UART_interface intf;
  uvm_analysis_port #(UART_sequence_item) monitor_port;

  // Edge detect
  bit prev_reset;
  bit rd_prev;
  bit wr_prev;

  // For STATUS sampling
  logic last_tx_full;
  logic last_rx_empty;
  logic last_incorrect;
  logic last_tx_done;
  logic last_rx_done;
  logic [9:0] last_divsr;

  byte last_wdata_seen;

  function new(string name = "monitor", uvm_component parent);
    super.new(name, parent);
    monitor_port = new("monitor_port", this);

    prev_reset      = 1'b0;
    rd_prev         = 1'b0;
    wr_prev         = 1'b0;

    last_tx_full    = 1'b0;
    last_rx_empty   = 1'b1;
    last_incorrect  = 1'b0;
    last_tx_done    = 1'b0;
    last_rx_done    = 1'b0;
    last_divsr      = 10'd54;

    last_wdata_seen = 8'h00;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual UART_interface)::get(this, "*", "intf", intf)) begin
      `uvm_error(get_type_name(), "virtual interface not set for monitor")
    end
  endfunction

  task run_phase(uvm_phase phase);
    UART_sequence_item tr;

    forever begin
      @(negedge intf.CLK);

      // RESET rising edge
      if (intf.Reset && !prev_reset) begin
        rd_prev         = 1'b0;
        wr_prev         = 1'b0;
        last_wdata_seen = 8'h00;

        // refresh snapshots on reset entry
        last_tx_full    = intf.tx_full;
        last_rx_empty   = intf.rx_empty;
        last_incorrect  = intf.incorrect_send;
        last_tx_done    = intf.tx_done;
        last_rx_done    = intf.rx_done;
        last_divsr      = intf.divsr;

        tr = UART_sequence_item::type_id::create("tr_reset", this);
        tr.kind         = UART_sequence_item::TR_RESET;
        tr.Reset        = 1'b1;
        tr.check_enable = 1'b0;
        monitor_port.write(tr);
      end
      prev_reset = intf.Reset;

      // STATUS sampling when any status changes (even during reset)
      if ((intf.tx_full        !== last_tx_full)   ||
          (intf.rx_empty       !== last_rx_empty)  ||
          (intf.incorrect_send !== last_incorrect) ||
          (intf.tx_done        !== last_tx_done)   ||
          (intf.rx_done        !== last_rx_done)   ||
          (intf.divsr          !== last_divsr)) begin

        tr = UART_sequence_item::type_id::create("tr_status", this);
        tr.kind          = UART_sequence_item::TR_STATUS;
        tr.Reset         = intf.Reset;

        tr.tx_full        = intf.tx_full;
        tr.rx_empty       = intf.rx_empty;
        tr.incorrect_send = intf.incorrect_send;
        tr.tx_done        = intf.tx_done;
        tr.rx_done        = intf.rx_done;

        tr.divsr          = intf.divsr;

        tr.last_w_data    = last_wdata_seen;
        tr.w_data         = last_wdata_seen; // convenience for some coverpoints
        tr.check_enable   = 1'b0;

        monitor_port.write(tr);

        last_tx_full    = intf.tx_full;
        last_rx_empty   = intf.rx_empty;
        last_incorrect  = intf.incorrect_send;
        last_tx_done    = intf.tx_done;
        last_rx_done    = intf.rx_done;
        last_divsr      = intf.divsr;
      end

      // During reset, don't record functional WR/RD traffic
      if (intf.Reset) begin
        rd_prev = intf.rd_uart;
        wr_prev = intf.wr_uart;
        continue;
      end

      // WR event (rising edge). Driver guarantees it doesn't write when full.
      if (intf.wr_uart && !wr_prev) begin
        last_wdata_seen = intf.w_data;

        tr = UART_sequence_item::type_id::create("tr_wr", this);
        tr.kind          = UART_sequence_item::TR_WRITE;
        tr.Reset         = 1'b0;
        tr.w_data        = intf.w_data;

        tr.tx_full        = intf.tx_full;
        tr.rx_empty       = intf.rx_empty;
        tr.incorrect_send = intf.incorrect_send;
        tr.tx_done        = intf.tx_done;
        tr.rx_done        = intf.rx_done;

        tr.divsr          = intf.divsr;

        tr.check_enable   = 1'b0;
        monitor_port.write(tr);
      end

      // RD event (rising edge): capture r_data at negedge before consuming posedge
      if (intf.rd_uart && !rd_prev) begin
        tr = UART_sequence_item::type_id::create("tr_rd", this);
        tr.kind          = UART_sequence_item::TR_READ;
        tr.Reset         = 1'b0;

        tr.r_data        = intf.r_data;

        tr.tx_full        = intf.tx_full;
        tr.rx_empty       = intf.rx_empty;
        tr.incorrect_send = intf.incorrect_send;
        tr.tx_done        = intf.tx_done;
        tr.rx_done        = intf.rx_done;

        tr.divsr          = intf.divsr;

        // Scoreboard decides whether to compare (based on its expected queue)
        tr.check_enable   = 1'b0;
        monitor_port.write(tr);
      end

      wr_prev = intf.wr_uart;
      rd_prev = intf.rd_uart;
    end
  endtask
endclass

class base_sequence extends uvm_sequence#(UART_sequence_item);
  `uvm_object_utils(base_sequence)
  function new(string name = "base_sequence"); super.new(name); endfunction
endclass

class reset_sequence extends base_sequence;
  `uvm_object_utils(reset_sequence)
  function new(string name = "reset_sequence"); super.new(name); endfunction
  task body();
    UART_sequence_item it;
    it = UART_sequence_item::type_id::create("it_reset");
    start_item(it);
    it.kind  = UART_sequence_item::TR_RESET;
    it.Reset = 1'b1;
    it.do_write = 1'b0;
    it.do_read  = 1'b0;
    it.set_divsr = 1'b0;
    it.inject_rx_frame = 1'b0;
    finish_item(it);
  endtask
endclass

class single_wr_rd_sequence extends base_sequence;
  `uvm_object_utils(single_wr_rd_sequence)

  logic [7:0] value;

  function new(string name = "single_wr_rd_sequence");
    super.new(name);
    value = 8'h00;
  endfunction

  task body();
    UART_sequence_item it;
    it = UART_sequence_item::type_id::create("it_single");
    start_item(it);
    it.kind  = UART_sequence_item::TR_WRITE;
    it.Reset = 1'b0;
    it.do_write = 1'b1;
    it.do_read  = 1'b1;
    it.read_delay_cycles = 0;
    it.w_data = value;
    it.set_divsr = 1'b0;
    it.inject_rx_frame = 1'b0;
    it.bad_parity = 1'b0;
    it.bad_stop   = 1'b0;
    finish_item(it);
  endtask
endclass

class all_zero_sequence extends single_wr_rd_sequence;
  `uvm_object_utils(all_zero_sequence)
  function new(string name="all_zero_sequence");
    super.new(name);
    value = 8'h00;
  endfunction
endclass

class all_one_sequence extends single_wr_rd_sequence;
  `uvm_object_utils(all_one_sequence)
  function new(string name="all_one_sequence");
    super.new(name);
    value = 8'hFF;
  endfunction
endclass

class pat_aa_sequence extends single_wr_rd_sequence;
  `uvm_object_utils(pat_aa_sequence)
  function new(string name="pat_aa_sequence");
    super.new(name);
    value = 8'hAA;
  endfunction
endclass

class pat_55_sequence extends single_wr_rd_sequence;
  `uvm_object_utils(pat_55_sequence)
  function new(string name="pat_55_sequence");
    super.new(name);
    value = 8'h55;
  endfunction
endclass

// Fill TX FIFO until FULL for a specific pattern, then drain reads
class fill_tx_full_sequence extends base_sequence;
  `uvm_object_utils(fill_tx_full_sequence)

  logic [7:0] fill_byte = 8'h00;
  int unsigned depth = 32;

  function new(string name="fill_tx_full_sequence");
    super.new(name);
  endfunction

  task body();
    UART_sequence_item it;

    // burst writes (no reads)
    for (int unsigned i=0; i<depth; i++) begin
      it = UART_sequence_item::type_id::create($sformatf("it_fill_wr_%0d", i));
      start_item(it);
      it.kind  = UART_sequence_item::TR_WRITE;
      it.Reset = 1'b0;
      it.do_write = 1'b1;
      it.do_read  = 1'b0;
      it.w_data   = fill_byte;
      it.set_divsr = 1'b0; // keep default 54 (fast enough, still fills FIFO)
      it.inject_rx_frame = 1'b0;
      finish_item(it);
    end

    // drain reads (so scoreboard queue stays aligned)
    for (int unsigned j=0; j<depth; j++) begin
      it = UART_sequence_item::type_id::create($sformatf("it_fill_rd_%0d", j));
      start_item(it);
      it.kind  = UART_sequence_item::TR_READ;
      it.Reset = 1'b0;
      it.do_write = 1'b0;
      it.do_read  = 1'b1;
      it.read_delay_cycles = 0;
      it.set_divsr = 1'b0;
      it.inject_rx_frame = 1'b0;
      finish_item(it);
    end
  endtask
endclass

// External RX bad parity injection
class rx_bad_parity_sequence extends base_sequence;
  `uvm_object_utils(rx_bad_parity_sequence)

  int unsigned n_frames = 10;
  logic [9:0]  divsr    = 10'd54;

  function new(string name="rx_bad_parity_sequence");
    super.new(name);
  endfunction

  task body();
    UART_sequence_item it;

    // set divsr for bit timing (optional)
    it = UART_sequence_item::type_id::create("it_set_divsr");
    start_item(it);
    it.kind      = UART_sequence_item::TR_STATUS;
    it.Reset     = 1'b0;
    it.do_write  = 1'b0;
    it.do_read   = 1'b0;
    it.set_divsr = 1'b1;
    it.divsr     = divsr;
    it.inject_rx_frame = 1'b0;
    finish_item(it);

    for (int unsigned i=0; i<n_frames; i++) begin
      it = UART_sequence_item::type_id::create($sformatf("it_badpar_%0d", i));
      start_item(it);
      it.kind  = UART_sequence_item::TR_WRITE; // kind doesn't matter for driver; monitor will create STATUS anyway
      it.Reset = 1'b0;
      it.do_write = 1'b0;
      it.do_read  = 1'b0; // không cần read để hit incorrect_send
      it.inject_rx_frame = 1'b1;
      it.bad_parity = 1'b1;
      it.bad_stop   = 1'b0;
      it.w_data     = $urandom_range(0,255);
      it.set_divsr  = 1'b0;
      finish_item(it);
    end
  endtask
endclass

class random_mix_sequence extends base_sequence;
  `uvm_object_utils(random_mix_sequence)

  int unsigned num_txn      = 500; // tổng “chunk”
  int unsigned max_burst    = 16;  // an toàn < 32 (FIFO depth)
  int unsigned max_rd_delay = 5;

  function new(string name="random_mix_sequence");
    super.new(name);
  endfunction

  task body();
    UART_sequence_item it;
    int unsigned k;
    int unsigned burst_len;
    int unsigned i;
    int op;

    // Allow override from command line
    void'($value$plusargs("RAND_TXN=%d", num_txn));
    void'($value$plusargs("RAND_MAX_BURST=%d", max_burst));
    void'($value$plusargs("RAND_MAX_RD_DLY=%d", max_rd_delay));

    if (max_burst > 32) max_burst = 32; // chặn overflow ngu

    for (k = 0; k < num_txn; k++) begin
      op = $urandom_range(0, 1);

      // 0: single write+read (an toàn, không overflow)
      if (op == 0) begin
        it = UART_sequence_item::type_id::create($sformatf("rand_single_%0d", k));
        start_item(it);
          it.kind   = UART_sequence_item::TR_WRITE;
          it.Reset  = 1'b0;
          it.do_write = 1'b1;
          it.do_read  = 1'b1;
          it.read_delay_cycles = $urandom_range(0, max_rd_delay);
          it.w_data = $urandom_range(0, 255);
          it.set_divsr = 1'b0;
          it.inject_rx_frame = 1'b0;
        finish_item(it);
      end
      // 1: burst write-only rồi drain read-only (system-like hơn)
      else begin
        burst_len = $urandom_range(1, max_burst);

        // burst writes
        for (i = 0; i < burst_len; i++) begin
          it = UART_sequence_item::type_id::create($sformatf("rand_bwr_%0d_%0d", k, i));
          start_item(it);
            it.kind = UART_sequence_item::TR_WRITE;
            it.Reset = 1'b0;
            it.do_write = 1'b1;
            it.do_read  = 1'b0;
            it.w_data = $urandom_range(0, 255);
            it.set_divsr = 1'b0;
            it.inject_rx_frame = 1'b0;
          finish_item(it);
        end

        // drain reads
        for (i = 0; i < burst_len; i++) begin
          it = UART_sequence_item::type_id::create($sformatf("rand_brd_%0d_%0d", k, i));
          start_item(it);
            it.kind = UART_sequence_item::TR_READ;
            it.Reset = 1'b0;
            it.do_write = 1'b0;
            it.do_read  = 1'b1;
            it.read_delay_cycles = $urandom_range(0, max_rd_delay);
            it.set_divsr = 1'b0;
            it.inject_rx_frame = 1'b0;
          finish_item(it);
        end
      end
    end
  endtask
endclass


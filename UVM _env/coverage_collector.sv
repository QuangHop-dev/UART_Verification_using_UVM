class coverage_collector extends uvm_subscriber #(UART_sequence_item);
  `uvm_component_utils(coverage_collector)

  UART_sequence_item item;
  uvm_analysis_imp #(UART_sequence_item, coverage_collector) coverage_collector_in_imp;

  covergroup UART_cg;
    option.per_instance = 1;

    KIND: coverpoint item.kind {
      bins rst    = {UART_sequence_item::TR_RESET};
      bins wr     = {UART_sequence_item::TR_WRITE};
      bins rd     = {UART_sequence_item::TR_READ};
      bins status = {UART_sequence_item::TR_STATUS};
    }

    RESET: coverpoint item.Reset {
      bins deasserted = {0};
      bins asserted   = {1};
    }

    // WRITE-only
    W_DATA: coverpoint item.w_data iff (item.kind == UART_sequence_item::TR_WRITE) {
      bins bin_all_zeros = {8'h00};
      bins bin_all_ones  = {8'hFF};
      bins bin_pat_aa    = {8'hAA};
      bins bin_pat_55    = {8'h55};
      bins default_bin_others = default;
    }

    // READ-only
    R_DATA: coverpoint item.r_data iff (item.kind == UART_sequence_item::TR_READ) {
      bins bin_all_zeros = {8'h00};
      bins bin_all_ones  = {8'hFF};
      bins bin_pat_aa    = {8'hAA};
      bins bin_pat_55    = {8'h55};
      bins default_bin_others = default;
    }

    // STATUS-only
    TX_FULL: coverpoint item.tx_full iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins bin_not_full = {0};
      bins bin_full     = {1};
    }

    // data-tagged-for-status (for cross)
    WDATA_STATUS: coverpoint item.last_w_data iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins bin_all_zeros = {8'h00};
      bins bin_all_ones  = {8'hFF};
      bins bin_pat_aa    = {8'hAA};
      bins bin_pat_55    = {8'h55};
      bins default_bin_others = default;
    }

    RX_EMPTY: coverpoint item.rx_empty iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins bin_not_empty = {0};
      bins bin_empty     = {1};
    }

    INCORRECT_SEND: coverpoint item.incorrect_send iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins bin_ok  = {0};
      bins bin_err = {1};
    }

    // NEW: done pulses seen (as sampled by monitor)
    TX_DONE: coverpoint item.tx_done iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins low  = {0};
      bins high = {1};
    }

    RX_DONE: coverpoint item.rx_done iff (item.kind == UART_sequence_item::TR_STATUS) {
      bins low  = {0};
      bins high = {1};
    }

    // NEW: divider coverage (sampled from DUT pins via monitor)
    DIVSR: coverpoint item.divsr iff (item.kind == UART_sequence_item::TR_STATUS) {
	  bins d54       = {10'd54};
	  bins bin_small = {[10'd0:10'd20]};
	  bins bin_mid   = {[10'd21:10'd200]};
	  bins bin_big   = {[10'd201:10'd1023]};
	}


    // Cross: STATUS data × tx_full
    CROSS_WDATA_FULL: cross WDATA_STATUS, TX_FULL {
      bins all_zeros_not_full = binsof(WDATA_STATUS.bin_all_zeros) && binsof(TX_FULL.bin_not_full);
      bins all_zeros_full     = binsof(WDATA_STATUS.bin_all_zeros) && binsof(TX_FULL.bin_full);

      bins all_ones_not_full  = binsof(WDATA_STATUS.bin_all_ones)  && binsof(TX_FULL.bin_not_full);
      bins all_ones_full      = binsof(WDATA_STATUS.bin_all_ones)  && binsof(TX_FULL.bin_full);

      bins pat_aa_not_full    = binsof(WDATA_STATUS.bin_pat_aa)    && binsof(TX_FULL.bin_not_full);
      bins pat_aa_full        = binsof(WDATA_STATUS.bin_pat_aa)    && binsof(TX_FULL.bin_full);

      bins pat_55_not_full    = binsof(WDATA_STATUS.bin_pat_55)    && binsof(TX_FULL.bin_not_full);
      bins pat_55_full        = binsof(WDATA_STATUS.bin_pat_55)    && binsof(TX_FULL.bin_full);
    }

  endgroup

  function new(string name = "coverage_collector", uvm_component parent);
    super.new(name, parent);
    UART_cg = new();
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    coverage_collector_in_imp = new("coverage_collector_in_imp", this);
  endfunction

  function void write(UART_sequence_item t);
    item = UART_sequence_item::type_id::create("item");
    $cast(item, t);
    UART_cg.sample();
  endfunction

endclass

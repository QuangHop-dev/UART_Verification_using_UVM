class UART_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(UART_sequence_item)

  // Transaction kind
  typedef enum int unsigned {
    TR_RESET  = 0,
    TR_WRITE  = 1,
    TR_READ   = 2,
    TR_STATUS = 3
  } tr_kind_t;

  tr_kind_t kind = TR_WRITE;

  // Stimulus
  rand logic [7:0] w_data;
  rand logic       Reset;

  // Driver knobs
  bit          do_write = 1'b1;
  bit          do_read  = 1'b1;
  int unsigned read_delay_cycles = 0;

  // Optional divsr override
  bit        set_divsr = 1'b0;
  logic [9:0] divsr    = 10'd54;

  // External RX injection
  bit inject_rx_frame = 1'b0;
  bit bad_parity      = 1'b0;
  bit bad_stop        = 1'b0;

  // Observed from monitor
  logic [7:0] r_data;
  logic       tx_done, rx_done;
  logic       tx_full, rx_empty;
  logic       incorrect_send;

  // For STATUS transaction: last accepted w_data (for cross coverage)
  logic [7:0] last_w_data;

  // Scoreboard control
  bit check_enable = 1'b1;

  function new(string name = "UART_sequence_item");
    super.new(name);
  endfunction

endclass

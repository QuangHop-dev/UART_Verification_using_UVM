interface UART_interface (
    input logic CLK
);

  // DUT pins
  logic       Reset;
  logic       rd_uart, wr_uart;
  logic       rx;                 // TB -> DUT
  logic [7:0] w_data;
  logic [9:0] divsr;

  logic       rx_empty, tx_full;
  logic       tx;                 // DUT -> TB
  logic [7:0] r_data;
  logic       incorrect_send;
  logic       tx_done, rx_done;

  // Clocking blocks
  clocking drv_cb @(posedge CLK);
    default input #1step output #1step;
    output Reset, rd_uart, wr_uart, w_data, divsr, rx;
    input  rx_empty, tx_full, tx, r_data, incorrect_send, tx_done, rx_done;
  endclocking

  clocking mon_cb @(posedge CLK);
    default input #1step output #1step;
    input  Reset, rd_uart, wr_uart, w_data, divsr, rx;
    input  rx_empty, tx_full, tx, r_data, incorrect_send, tx_done, rx_done;
  endclocking

  // =========================
  // Simple assertions
  // =========================
  property p_no_rd_when_empty;
    @(posedge CLK) disable iff (Reset) !(rd_uart && rx_empty);
  endproperty
  a_no_rd_when_empty: assert property (p_no_rd_when_empty)
    else $error("UART_IF ASSERT: rd_uart asserted while rx_empty=1");

  property p_no_wr_when_full;
    @(posedge CLK) disable iff (Reset) !(wr_uart && tx_full);
  endproperty
  a_no_wr_when_full: assert property (p_no_wr_when_full)
    else $error("UART_IF ASSERT: wr_uart asserted while tx_full=1");

  property p_tx_done_pulse;
    @(posedge CLK) disable iff (Reset) tx_done |=> !tx_done;
  endproperty
  a_tx_done_pulse: assert property (p_tx_done_pulse)
    else $warning("UART_IF WARN: tx_done is not a 1-cycle pulse");

  property p_rx_done_pulse;
    @(posedge CLK) disable iff (Reset) rx_done |=> !rx_done;
  endproperty
  a_rx_done_pulse: assert property (p_rx_done_pulse)
    else $warning("UART_IF WARN: rx_done is not a 1-cycle pulse");

endinterface

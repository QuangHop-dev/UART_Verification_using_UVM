`timescale 1ns / 1ps

`include "uvm_macros.svh"
`include "UART_pkg.sv"
`include "UART_interface.sv"

module UART_TOP #(
  parameter bit LOOPBACK = 1'b1
);

  import uvm_pkg::*;
  import UART_pkg::*;

  // Clock
  logic CLK;
  initial CLK = 1'b0;
  always #5 CLK = ~CLK;

  // Interface
  UART_interface intf(.CLK(CLK));

  // DUT
  UART #(.LOOPBACK(LOOPBACK)) dut (
    .CLK           (CLK),
    .Reset         (intf.Reset),
    .rd_uart       (intf.rd_uart),
    .wr_uart       (intf.wr_uart),
    .rx            (intf.rx),
    .w_data        (intf.w_data),
    .divsr         (intf.divsr),
    .rx_empty      (intf.rx_empty),
    .tx_full       (intf.tx_full),
    .tx            (intf.tx),
    .r_data        (intf.r_data),
    .incorrect_send(intf.incorrect_send),
    .tx_done       (intf.tx_done),
    .rx_done       (intf.rx_done)
  );

  initial begin
    // Init signals (safe)
    intf.Reset   = 1'b0;
    intf.rd_uart = 1'b0;
    intf.wr_uart = 1'b0;
    intf.rx      = 1'b1;
    intf.w_data  = 8'h00;
    intf.divsr   = 10'd54;

    // Provide interface to UVM
    uvm_config_db#(virtual UART_interface)::set(null, "*", "intf", intf);

    // Allow +UVM_TESTNAME=<name>
    string testname;
    if (!$value$plusargs("UVM_TESTNAME=%s", testname))
      testname = "test";

    run_test(testname);
  end

endmodule

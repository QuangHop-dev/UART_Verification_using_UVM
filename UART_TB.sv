`timescale 1ns / 1ps
/*=========================================================
 * Module: UART_TB
 * Description:
 *   Testbench for UART top module
 *   - Generates clock and reset
 *   - Drives TX data via FIFO
 *   - Manually stimulates RX line
 *   - Verifies RX/TX operation
 *=========================================================*/
module UART_TB;

    /*=====================================================
     * Parameters
     *=====================================================*/
    parameter Data_bits        = 9;
    parameter Sp_ticks         = 16;
    parameter St_ticks         = 8;
    parameter Dt_ticks         = 16;
    parameter addr_width       = 5;
    parameter divsr_width      = 10;
    parameter Read             = 2'b01;
    parameter Write            = 2'b10;
    parameter Read_and_Write   = 2'b11;

    /*=====================================================
     * Testbench signals
     *=====================================================*/
    logic                     clk;
    logic                     Reset;
    logic                     rd_uart;
    logic                     wr_uart;
    logic                     rx;
    logic [Data_bits-2:0]     w_data;
    logic [divsr_width-1:0]   divsr;
    logic                     rx_empty;
    logic                     tx_full;
    logic                     tx;
    logic [Data_bits-2:0]     r_data;
    logic                     incorrect_send;
    // logic                  parity_bit;

    /*=====================================================
     * DUT instantiation
     *=====================================================*/
    UART #(
        .Data_bits        (Data_bits),
        .Sp_ticks         (Sp_ticks),
        .St_ticks         (St_ticks),
        .Dt_ticks         (Dt_ticks),
        .addr_width       (addr_width),
        .divsr_width      (divsr_width),
        .Read             (Read),
        .Write            (Write),
        .Read_and_Write   (Read_and_Write)
    ) UART_tb (
        .clk            (clk),
        .Reset          (Reset),
        .rd_uart        (rd_uart),
        .wr_uart        (wr_uart),
        .rx             (rx),
        .w_data         (w_data),
        .divsr          (divsr),
        .rx_empty       (rx_empty),
        .tx_full        (tx_full),
        .tx             (tx),
        .r_data         (r_data),
        .incorrect_send (incorrect_send)
        // .parity_bit   (parity_bit)
    );

    /*=====================================================
     * Initial values
     *=====================================================*/
    initial begin
        clk      = 1'b0;
        Reset    = 1'b0;
        rd_uart  = 1'b0;
        wr_uart  = 1'b0;
        rx       = 1'b1;

        /*-------------------------------------------------
         * Baud-rate divisor:
         *   clk = 100 MHz → Tclk = 10 ns
         *   Baud = 9600, oversampling = 16
         *   divsr = 100e6 / (9600 * 16) ≈ 650
         *-------------------------------------------------*/
        divsr = 10'd650;
    end

    /*=====================================================
     * Reset generation
     *=====================================================*/
    initial begin
        #10  Reset = 1'b1;
        #10  Reset = 1'b0;
    end

    /*=====================================================
     * Clock generation
     * 100 MHz → period = 10 ns
     *=====================================================*/
    always #5 clk = ~clk;

    /*=====================================================
     * Transmit data (TX FIFO write)
     *=====================================================*/
    initial begin
        #100;

        /* First TX data */
        w_data  = 8'b1110_0011;
        wr_uart = 1'b1;  #10;
        wr_uart = 1'b0;

        #1_090_000;

        /* Second TX data */
        w_data  = 8'b1111_0000;
        wr_uart = 1'b1;  #10;
        wr_uart = 1'b0;

        #1_090_000;
    end

    /*=====================================================
     * Receive data (RX line stimulus)
     *=====================================================*/
    initial begin
        #10_000;   // delay between TX and RX

        /*=================================================
         * First RX frame
         *=================================================*/
        rx = 1'b1; #10;

        // Start bit
        rx = 1'b0;
        #52_000;   // 8 ticks * 650 * 10 ns

        // Data bits (LSB first)
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;

        // Parity bit
        rx = 1'b0; #104_000;

        // Stop bit
        rx = 1'b1; #10_000;

        /*=================================================
         * Second RX frame
         *=================================================*/
        rx = 1'b1; #10;

        // Start bit
        rx = 1'b0;
        #52_000;

        // Data bits
        rx = 1'b0; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b0; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;
        rx = 1'b1; #104_000;

        // Parity bit
        rx = 1'b0; #104_000;

        // Stop bit
        rx = 1'b1;
    end

endmodule

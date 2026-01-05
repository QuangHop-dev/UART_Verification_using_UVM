`timescale 1ns / 1ps
/*=========================================================
 * Module: UART
 * Description:
 *   Top-level UART module
 *   - Includes TX, RX, FIFOs, and Baud-rate generator
 *   - Supports buffered transmit and receive
 *
 * Parameters:
 *   Data_bits        : Total data bits (including parity if used)
 *   Sp_ticks         : Sampling ticks per bit
 *   St_ticks         : Start bit ticks
 *   Dt_ticks         : Data bit ticks
 *   addr_width       : FIFO address width
 *   divsr_width      : Baud rate divisor width
 *   Read             : FIFO read encoding
 *   Write            : FIFO write encoding
 *   Read_and_Write   : FIFO simultaneous R/W encoding
 *=========================================================*/
module UART #(
    parameter Data_bits        = 9,
    parameter Sp_ticks         = 16,
    parameter St_ticks         = 8,
    parameter Dt_ticks         = 16,
    parameter addr_width       = 5,
    parameter divsr_width      = 10,
    parameter Read             = 2'b01,
    parameter Write            = 2'b10,
    parameter Read_and_Write   = 2'b11
)(
    /*-------------------------
     * Clock & Reset
     *-------------------------*/
    input  logic                    clk,
    input  logic                    Reset,

    /*-------------------------
     * UART interface
     *-------------------------*/
    input  logic                    rd_uart,
    input  logic                    wr_uart,
    input  logic                    rx,
    output logic                    tx,

    /*-------------------------
     * Data interface
     *-------------------------*/
    input  logic [Data_bits-2:0]    w_data,
    output logic [Data_bits-2:0]    r_data,

    /*-------------------------
     * Baud rate control
     *-------------------------*/
    input  logic [divsr_width-1:0]  divsr,

    /*-------------------------
     * Status signals
     *-------------------------*/
    output logic                    rx_empty,
    output logic                    tx_full,
    output logic                    incorrect_send,
    output logic                    tx_done,
    output logic                    rx_done
    // output logic                parity_bit
);

    /*=====================================================
     * Internal signals
     *=====================================================*/
    logic s_ticks;

    /* RX path */
    logic rx_done_tick;
    logic [Data_bits-2:0] rx_data_out;

    /* TX path */
    logic tx_done_tick;
    logic tx_start;
    logic [Data_bits-2:0] fifo_tx_data_out;

    /* FIFO status */
    logic full_fifo_out;
    logic empty_tx_fifo;

    /* Parity */
    logic parity_check;

    /*=====================================================
     * Control logic
     *=====================================================*/
    assign tx_start = ~empty_tx_fifo;

    assign tx_done  = tx_done_tick;
    assign rx_done  = rx_done_tick;

    /*=====================================================
     * UART Transmitter
     *=====================================================*/
    UART_TX #(
        .Data_bits (Data_bits),
        .Sp_ticks  (Sp_ticks),
        .St_ticks  (St_ticks),
        .Dt_ticks  (Dt_ticks)
    ) TX (
        .clk          (clk),
        .Reset        (Reset),
        .s_ticks      (s_ticks),
        .tx_start     (tx_start),
        .tx           (tx),
        .tx_done_tick (tx_done_tick),
        .parity_check (parity_check),
        .data_in      (fifo_tx_data_out)
    );

    /*=====================================================
     * UART Receiver
     *=====================================================*/
    UART_RX #(
        .Data_bits (Data_bits),
        .Sp_ticks  (Sp_ticks),
        .St_ticks  (St_ticks),
        .Dt_ticks  (Dt_ticks)
    ) RX (
        .clk            (clk),
        .Reset          (Reset),
        .rx             (rx),
        .s_ticks        (s_ticks),
        .data_out       (rx_data_out),
        .rx_done_tick   (rx_done_tick),
        .incorrect_send (incorrect_send)
        // .parity_bit   (parity_bit)
    );

    /*=====================================================
     * RX FIFO
     * - Stores received data
     *=====================================================*/
    FIFO #(
        .addr_width      (addr_width),
        .Data_bits       (Data_bits-1),
        .Read            (Read),
        .Write           (Write),
        .Read_and_Write  (Read_and_Write)
    ) FIFO_RX (
        .clk    (clk),
        .Reset  (Reset),
        .wr     (rx_done_tick),
        .rd     (rd_uart),
        .w_data (rx_data_out),
        .r_data (r_data),
        .full   (full_fifo_out),
        .empty  (rx_empty)
    );

    /*=====================================================
     * TX FIFO
     * - Buffers data before transmission
     *=====================================================*/
    FIFO #(
        .addr_width      (addr_width),
        .Data_bits       (Data_bits-1),
        .Read            (Read),
        .Write           (Write),
        .Read_and_Write  (Read_and_Write)
    ) FIFO_TX (
        .clk    (clk),
        .Reset  (Reset),
        .wr     (wr_uart),
        .rd     (tx_done_tick),
        .w_data (w_data),
        .r_data (fifo_tx_data_out),
        .full   (tx_full),
        .empty  (empty_tx_fifo)
    );

    /*=====================================================
     * Baud Rate Generator
     *=====================================================*/
    Baud_rate_gen #(
        .divsr_width (divsr_width)
    ) Baud_Gen (
        .clk   (clk),
        .Reset (Reset),
        .divsr (divsr),
        .tick  (s_ticks)
    );

endmodule

`timescale 1ns / 1ps
/*=========================================================
 * Module: FIFO
 * Description:
 *   FIFO synchronous with separate read/write control.
 *   Includes:
 *     - FIFO controller (address & status management)
 *     - Register file (data storage)
 *
 * Parameters:
 *   addr_width        : FIFO depth = 2^addr_width
 *   Data_bits         : Data width
 *   Read              : Read operation encoding
 *   Write             : Write operation encoding
 *   Read_and_Write    : Simultaneous read & write encoding
 *=========================================================*/
module FIFO #(
    parameter addr_width       = 5,
    parameter Data_bits        = 9,
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
     * Control signals
     *-------------------------*/
    input  logic                    wr,
    input  logic                    rd,

    /*-------------------------
     * Data interface
     *-------------------------*/
    input  logic [Data_bits-1:0]    w_data,
    output logic [Data_bits-1:0]    r_data,

    /*-------------------------
     * Status flags
     *-------------------------*/
    output logic                    full,
    output logic                    empty
);

    /*=====================================================
     * Internal signals
     *=====================================================*/
    logic [addr_width-1:0] w_addr;   // write pointer
    logic [addr_width-1:0] r_addr;   // read pointer
    logic                  w_en;     // write enable (masked by full)

    /*=====================================================
     * Write enable logic
     * Write allowed only when FIFO is not full
     *=====================================================*/
    assign w_en = wr & (~full);

    /*=====================================================
     * FIFO Controller
     * - Manages read/write pointers
     * - Generates full/empty flags
     *=====================================================*/
    FIFO_Contr #(
        .addr_width       (addr_width),
        .Read             (Read),
        .Write            (Write),
        .Read_and_Write   (Read_and_Write)
    ) controller (
        .clk    (clk),
        .Reset  (Reset),
        .wr     (wr),
        .rd     (rd),
        .full   (full),
        .empty  (empty),
        .w_addr (w_addr),
        .r_addr (r_addr)
    );

    /*=====================================================
     * Register File
     * - Stores FIFO data
     * - Write controlled by w_en
     *=====================================================*/
    Regsiter_file #(
        .addr_width (addr_width),
        .Data_bits  (Data_bits)
    ) reg_file (
        .clk    (clk),
        .w_en   (w_en),
        .w_data (w_data),
        .w_addr (w_addr),
        .r_addr (r_addr),
        .r_data (r_data)
    );

endmodule

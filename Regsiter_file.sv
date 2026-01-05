`timescale 1ns / 1ps
/*=========================================================
 * Module: Regsiter_file
 * Description:
 *   Register file used as FIFO storage
 *   - Synchronous write
 *   - Asynchronous read
 *
 * Parameters:
 *   addr_width : Address width (depth = 2^addr_width)
 *   Data_bits  : Data width
 *=========================================================*/
module Regsiter_file #(
    parameter addr_width = 5,
    parameter Data_bits  = 9
)(
    /*-------------------------
     * Clock
     *-------------------------*/
    input  logic                    clk,

    /*-------------------------
     * Write interface
     *-------------------------*/
    input  logic                    w_en,
    input  logic [Data_bits-1:0]    w_data,
    input  logic [addr_width-1:0]   w_addr,

    /*-------------------------
     * Read interface
     *-------------------------*/
    input  logic [addr_width-1:0]   r_addr,
    output logic [Data_bits-1:0]    r_data
);

    /*=====================================================
     * Register file memory
     * Depth = 2^addr_width
     *=====================================================*/
    logic [Data_bits-1:0] reg_file [0:(2**addr_width)-1];

    /*=====================================================
     * Synchronous write logic
     *=====================================================*/
    always_ff @(posedge clk) begin
        if (w_en) begin
            reg_file[w_addr] <= w_data;
        end
    end

    /*=====================================================
     * Asynchronous read logic
     *=====================================================*/
    assign r_data = reg_file[r_addr];

endmodule

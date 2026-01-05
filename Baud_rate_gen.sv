`timescale 1ns / 1ps
/*=========================================================
 * Module: Baud_rate_gen
 * Description:
 *   Baud rate (tick) generator
 *   - Counts clock cycles up to a programmable divisor
 *   - Generates a single-cycle tick when count == divsr
 *
 * Parameters:
 *   divsr_width : Width of divisor and counter
 *=========================================================*/
module Baud_rate_gen #(
    parameter divsr_width = 10
)(
    /*-------------------------
     * Clock & Reset
     *-------------------------*/
    input  logic                     clk,
    input  logic                     Reset,

    /*-------------------------
     * Divisor input
     *-------------------------*/
    input  logic [divsr_width-1:0]   divsr,

    /*-------------------------
     * Tick output
     *-------------------------*/
    output logic                     tick
);

    /*=====================================================
     * Internal counter signals
     *=====================================================*/
    logic [divsr_width-1:0] count_logic;
    logic [divsr_width-1:0] count_next;

    /*=====================================================
     * Sequential logic
     * - Counter register
     * - Asynchronous reset
     *=====================================================*/
    always_ff @(posedge clk or posedge Reset) begin
        if (Reset)
            count_logic <= '0;
        else
            count_logic <= count_next;
    end

    /*=====================================================
     * Combinational logic
     * - Next counter value
     *=====================================================*/
    always_comb begin
        if (count_logic == divsr)
            count_next = '0;
        else
            count_next = count_logic + 1'b1;
    end

    /*=====================================================
     * Tick generation
     * - Asserted for 1 clock cycle when count == divsr
     *=====================================================*/
    assign tick = (count_logic == divsr);

endmodule

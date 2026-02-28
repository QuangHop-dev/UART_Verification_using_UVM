`timescale 1ns / 1ps
/*=========================================================
 * Module: FIFO_Contr
 * Description:
 *   FIFO control unit
 *   - Manages read/write pointers
 *   - Generates full and empty flags
 *   - Supports read, write, and simultaneous read/write
 *
 * Parameters:
 *   addr_width        : Address width (FIFO depth = 2^addr_width)
 *   Read              : Read operation encoding
 *   Write             : Write operation encoding
 *   Read_and_Write    : Simultaneous read & write encoding
 *=========================================================*/
module FIFO_Contr #(
    parameter addr_width       = 5,
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
     * Control inputs
     *-------------------------*/
    input  logic                    wr,
    input  logic                    rd,

    /*-------------------------
     * Status outputs
     *-------------------------*/
    output logic                    full,
    output logic                    empty,

    /*-------------------------
     * Address outputs
     *-------------------------*/
    output logic [addr_width-1:0]    w_addr,
    output logic [addr_width-1:0]    r_addr
);

    /*=====================================================
     * Internal state registers
     *=====================================================*/
    logic full_logic,  full_next;
    logic empty_logic, empty_next;

    logic [addr_width-1:0] wr_ptr_logic, wr_ptr_next, wr_ptr_succ;
    logic [addr_width-1:0] rd_ptr_logic, rd_ptr_next, rd_ptr_succ;

    /*=====================================================
     * Sequential logic
     * - State update on clock edge
     * - Asynchronous reset
     *=====================================================*/
    always_ff @(posedge clk or posedge Reset) begin
        if (Reset) begin
            full_logic   <= 1'b0;
            empty_logic  <= 1'b1;
            wr_ptr_logic <= '0;
            rd_ptr_logic <= '0;
        end
        else begin
            full_logic   <= full_next;
            empty_logic  <= empty_next;
            wr_ptr_logic <= wr_ptr_next;
            rd_ptr_logic <= rd_ptr_next;
        end
    end

    /*=====================================================
     * Combinational logic
     * - Next-state logic
     *=====================================================*/
    always_comb begin
        /*-------------------------
         * Default assignments
         *-------------------------*/
        full_next   = full_logic;
        empty_next  = empty_logic;
        wr_ptr_next = wr_ptr_logic;
        rd_ptr_next = rd_ptr_logic;

        /*-------------------------
         * Successive pointer values
         *-------------------------*/
        wr_ptr_succ = wr_ptr_logic + 1'b1;
        rd_ptr_succ = rd_ptr_logic + 1'b1;

        /*-------------------------
         * Operation decoding
         *-------------------------*/
        unique case ({wr, rd})

            /*---------------------
             * Read operation
             *---------------------*/
            Read: begin
                if (!empty_logic) begin
                    rd_ptr_next = rd_ptr_succ;
                    full_next   = 1'b0;

                    if (rd_ptr_succ == wr_ptr_logic)
                        empty_next = 1'b1;
                end
            end

            /*---------------------
             * Write operation
             *---------------------*/
            Write: begin
                if (!full_logic) begin
                    wr_ptr_next = wr_ptr_succ;
                    empty_next  = 1'b0;

                    if (wr_ptr_succ == rd_ptr_logic)
                        full_next = 1'b1;
                end
            end

            /*---------------------
             * Simultaneous
             * Read & Write
             *---------------------*/
            Read_and_Write: begin
                wr_ptr_next = wr_ptr_succ;
                rd_ptr_next = rd_ptr_succ;
            end

            /*---------------------
             * No operation
             *---------------------*/
            default: begin
                /* no-op */
            end

        endcase
    end

    /*=====================================================
     * Output assignments
     *=====================================================*/
    assign full   = full_logic;
    assign empty  = empty_logic;
    assign w_addr = wr_ptr_logic;
    assign r_addr = rd_ptr_logic;

endmodule

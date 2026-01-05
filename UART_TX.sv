`timescale 1ns / 1ps
/*=========================================================
 * Module: UART_TX
 * Description:
 *   UART Transmitter FSM
 *   - Sends start bit
 *   - Transmits data bits
 *   - Generates parity bit
 *   - Sends stop bit
 *
 * Parameters:
 *   Data_bits : Total bits (data + parity)
 *   Sp_ticks  : Stop-bit ticks
 *   St_ticks  : Start-bit ticks
 *   Dt_ticks  : Data-bit ticks
 *=========================================================*/
module UART_TX #(
    parameter Data_bits = 9,   // including parity bit
    parameter Sp_ticks  = 16,  // stop-bit ticks
    parameter St_ticks  = 8,   // start-bit ticks
    parameter Dt_ticks  = 16   // data-bit ticks
)(
    /*-------------------------
     * Inputs
     *-------------------------*/
    input  logic                    clk,
    input  logic                    Reset,
    input  logic [Data_bits-2:0]    data_in,
    input  logic                    tx_start,
    input  logic                    s_ticks,

    /*-------------------------
     * Outputs
     *-------------------------*/
    output logic                    tx_done_tick,
    output logic                    parity_check,
    output logic                    tx
);

    /*=====================================================
     * FSM state declaration
     *=====================================================*/
    typedef enum logic [1:0] {
        idle,
        start,
        data,
        stop
    } S_states;

    S_states state_reg, state_next;

    /*=====================================================
     * Internal registers
     *=====================================================*/
    logic                         tx_reg, tx_next;
    logic [$clog2(Dt_ticks)-1:0]  s_reg, s_next;      // tick counter
    logic [$clog2(Data_bits)-1:0] n_reg, n_next;      // bit counter
    logic [Data_bits-2:0]         sd_reg, sd_next;    // shift register
    logic                         parity_reg, parity_next;

    /*=====================================================
     * Sequential logic
     *=====================================================*/
    always_ff @(posedge clk or posedge Reset) begin
        if (Reset) begin
            state_reg   <= idle;
            tx_reg      <= 1'b1;
            s_reg       <= '0;
            n_reg       <= '0;
            sd_reg      <= '0;
            parity_reg  <= 1'b0; //change if bits is odd
        end
        else begin
            state_reg   <= state_next;
            s_reg       <= s_next;
            n_reg       <= n_next;
            sd_reg      <= sd_next;
            parity_reg  <= parity_next;

            /* Transmitted bit selection */
            if (n_reg == Data_bits-1)
                tx_reg <= parity_check;
            else
                tx_reg <= tx_next;
        end
    end

    /*=====================================================
     * Combinational logic
     *=====================================================*/
    always_comb begin
        /*-------------------------
         * Default assignments
         *-------------------------*/
        state_next     = state_reg;
        s_next         = s_reg;
        n_next         = n_reg;
        sd_next        = sd_reg;
        tx_next        = tx_reg;
        parity_next    = parity_reg;
        tx_done_tick   = 1'b0;
        parity_check   = 1'b0;

        case (state_reg)

            /*---------------------
             * Idle state
             *---------------------*/
            idle: begin
                tx_next = 1'b1; // line idle high
                if (tx_start) begin
                    s_next     = '0;
                    sd_next    = data_in;
                    parity_next= 1'b0;
                    state_next = start;
                end
            end

            /*---------------------
             * Start bit
             *---------------------*/
            start: begin
                tx_next = 1'b0;
                if (s_ticks) begin
                    if (s_reg == St_ticks-1) begin
                        s_next     = '0;
                        n_next     = '0;
                        state_next = data;
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            /*---------------------
             * Data transmission
             *---------------------*/
            data: begin
                tx_next = sd_reg[0];
                if (s_ticks) begin
                    if (s_reg == Dt_ticks-1) begin
                        s_next  = '0;
                        sd_next = sd_reg >> 1;

                        if (n_reg == Data_bits-1) begin
                            n_next     = '0;
                            state_next = stop;
                        end
                        else begin
                            n_next      = n_reg + 1'b1;
                            parity_next = parity_reg ^ tx_next;

                            if (n_reg == Data_bits-2)
                                parity_check = parity_next;
                        end
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            /*---------------------
             * Stop bit
             *---------------------*/
            stop: begin
                tx_next = 1'b1;
                if (s_ticks) begin
                    if (s_reg == Sp_ticks-1) begin
                        tx_done_tick = 1'b1;
                        state_next   = idle;
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            default: state_next = idle;

        endcase
    end

    /*=====================================================
     * Output assignment
     *=====================================================*/
    assign tx = tx_reg;

endmodule

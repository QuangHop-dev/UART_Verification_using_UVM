`timescale 1ns / 1ps
/*=========================================================
 * Module: UART_RX
 * Description:
 *   UART Receiver FSM
 *   - Detects start bit
 *   - Samples data bits
 *   - Checks parity
 *   - Verifies stop bit
 *
 * Parameters:
 *   Data_bits : Total bits (data + parity)
 *   Sp_ticks  : Stop-bit ticks
 *   St_ticks  : Start-bit ticks
 *   Dt_ticks  : Data-bit ticks
 *=========================================================*/
module UART_RX #(
    parameter Data_bits = 9,
    parameter Sp_ticks  = 16, // Stop-bit ticks
    parameter St_ticks  = 8,  // Start-bit ticks
    parameter Dt_ticks  = 16  // Data-bit ticks
)(
    /*-------------------------
     * Inputs
     *-------------------------*/
    input  logic                    rx,
    input  logic                    clk,
    input  logic                    Reset,
    input  logic                    s_ticks,

    /*-------------------------
     * Outputs
     *-------------------------*/
    output logic                    rx_done_tick,
    output logic [Data_bits-2:0]    data_out,
    output logic                    incorrect_send
    // output logic                parity_bit
);

    /*=====================================================
     * FSM state declaration
     *=====================================================*/
    typedef enum logic [2:0] {
        idle,
        start,
        data,
        parity,
        stop
    } S_states;

    S_states state_reg, state_next;

    /*=====================================================
     * Internal registers
     *=====================================================*/
    logic [$clog2(Dt_ticks)-1:0]   s_reg, s_next;   // tick counter
    logic [$clog2(Data_bits)-1:0]  n_reg, n_next;   // bit counter
    logic [Data_bits-2:0]          sd_reg, sd_next; // shift register
    logic                          parity_reg, parity_next;

    /*=====================================================
     * Sequential logic
     *=====================================================*/
    always_ff @(posedge clk or posedge Reset) begin
        if (Reset) begin
            state_reg   <= idle;
            s_reg       <= '0;
            n_reg       <= '0;
            sd_reg      <= '0;
            parity_reg  <= 1'b0;
        end
        else begin
            state_reg   <= state_next;
            s_reg       <= s_next;
            n_reg       <= n_next;
            sd_reg      <= sd_next;
            parity_reg  <= parity_next;
        end
    end

    /*=====================================================
     * Combinational logic
     *=====================================================*/
    always_comb begin
        /*-------------------------
         * Default assignments
         *-------------------------*/
        state_next      = state_reg;
        s_next          = s_reg;
        n_next          = n_reg;
        sd_next         = sd_reg;
        parity_next     = parity_reg;
        rx_done_tick    = 1'b0;
        incorrect_send  = 1'b0;

        case (state_reg)

            /*---------------------
             * Idle state
             *---------------------*/
            idle: begin
                if (!rx) begin              // start bit detected
                    s_next     = '0;
                    state_next = start;
                end
            end

            /*---------------------
             * Start bit sampling
             *---------------------*/
            start: begin
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
             * Data reception
             *---------------------*/
            data: begin
                if (s_ticks) begin
                    if (s_reg == Dt_ticks-1) begin
                        sd_next     = {rx, sd_reg[Data_bits-2:1]};
                        parity_next = parity_reg ^ rx;
                        s_next      = '0;

                        if (n_reg == Data_bits-2)
                            state_next = parity;
                        else
                            n_next = n_reg + 1'b1;
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            /*---------------------
             * Parity check
             *---------------------*/
            parity: begin
                if (s_ticks) begin
                    if (s_reg == Dt_ticks-1) begin
                        parity_next    = parity_reg ^ rx;
                        incorrect_send = (parity_reg == rx);
                        s_next         = '0;
                        state_next     = stop;
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            /*---------------------
             * Stop bit
             *---------------------*/
            stop: begin
                if (s_ticks) begin
                    if (s_reg == Sp_ticks-1) begin
                        state_next   = idle;
                        rx_done_tick = 1'b1;
                    end
                    else
                        s_next = s_reg + 1'b1;
                end
            end

            default: state_next = idle;

        endcase
    end

    /*=====================================================
     * Output data
     *=====================================================*/
    assign data_out = sd_reg;

endmodule

//=============================================================================
// File: debouncer.sv
// Description: Glitch filter and edge detector for noisy mechanical pushbuttons
//              on FPGA development boards (Spartan-6 / Nexys / Basys).
//=============================================================================

`ifndef DEBOUNCER_SV
`define DEBOUNCER_SV

module debouncer #(
    parameter int CLK_FREQ_HZ = 50_000_000,
    parameter int DEBOUNCE_MS = 20
)(
    input  logic clk_i,
    input  logic rst_ni,
    input  logic btn_i,
    output logic btn_state_o,
    output logic btn_posedge_o
);

    localparam int THRESHOLD = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;

    logic [$clog2(THRESHOLD)-1:0] counter;
    logic btn_sync_0, btn_sync_1;
    logic btn_state_prev;

    // 2-Stage synchronizer to prevent metastability
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_i;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Counter-based glitch filter
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter        <= '0;
            btn_state_o    <= 1'b0;
            btn_state_prev <= 1'b0;
        end else begin
            btn_state_prev <= btn_state_o;
            if (btn_sync_1 != btn_state_o) begin
                counter <= counter + 1'b1;
                if (counter >= THRESHOLD[$clog2(THRESHOLD)-1:0]) begin
                    btn_state_o <= btn_sync_1;
                    counter     <= '0;
                end
            end else begin
                counter <= '0;
            end
        end
    end

    // 1-Cycle positive edge pulse
    assign btn_posedge_o = btn_state_o && !btn_state_prev;

endmodule: debouncer

`endif

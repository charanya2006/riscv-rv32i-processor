//=============================================================================
// File: clk_divider.sv
// Description: Configurable clock divider for Spartan-6 FPGA board deployment.
//              Generates a slower core clock (e.g. 10 MHz from 50 MHz or 100 MHz)
//              and a 1 kHz refresh clock for seven-segment display multiplexing.
//=============================================================================

`ifndef CLK_DIVIDER_SV
`define CLK_DIVIDER_SV

module clk_divider #(
    parameter int INPUT_FREQ_HZ = 50_000_000,
    parameter int CORE_FREQ_HZ  = 10_000_000,
    parameter int DISP_FREQ_HZ  = 1_000
)(
    input  logic clk_i,
    input  logic rst_ni,
    output logic core_clk_o,
    output logic disp_clk_o
);

    localparam int CORE_DIV = INPUT_FREQ_HZ / (2 * CORE_FREQ_HZ);
    localparam int DISP_DIV = INPUT_FREQ_HZ / (2 * DISP_FREQ_HZ);

    logic [$clog2(CORE_DIV+1):0] core_cnt;
    logic [$clog2(DISP_DIV+1):0] disp_cnt;

    // Core Clock Generator
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            core_cnt   <= '0;
            core_clk_o <= 1'b0;
        end else if (core_cnt >= CORE_DIV - 1) begin
            core_cnt   <= '0;
            core_clk_o <= ~core_clk_o;
        end else begin
            core_cnt   <= core_cnt + 1'b1;
        end
    end

    // Display Multiplexing Clock Generator (1 kHz)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            disp_cnt   <= '0;
            disp_clk_o <= 1'b0;
        end else if (disp_cnt >= DISP_DIV - 1) begin
            disp_cnt   <= '0;
            disp_clk_o <= ~disp_clk_o;
        end else begin
            disp_cnt   <= disp_cnt + 1'b1;
        end
    end

endmodule: clk_divider

`endif

//=============================================================================
// File: spartan6_top.sv
// Description: Synthesizable FPGA Board Top Module for Xilinx Spartan-6.
//              Integrates RV32I Processor System with Clock Divider,
//              Button Debouncers, 7-Segment Hex Display, and Status LEDs.
//=============================================================================

`ifndef SPARTAN6_TOP_SV
`define SPARTAN6_TOP_SV

`include "rv32i_top.sv"
`include "clk_divider.sv"
`include "debouncer.sv"
`include "seven_seg_controller.sv"

module spartan6_top (
    input  logic        board_clk_i,    // 50 MHz or 100 MHz board oscillator
    input  logic        btn_rst_ni,     // Pushbutton reset (active-low)
    input  logic        btn_step_i,     // Pushbutton for single-cycle stepping
    input  logic [1:0]  sw_disp_sel_i,  // Switches to select 7-seg display data
    input  logic        sw_step_mode_i, // Switch: 1 = Continuous clock, 0 = Single step
    output logic [7:0]  led_o,          // 8 Board LEDs for core diagnostics
    output logic [3:0]  anode_o,        // 4 Seven-segment digit enables
    output logic [6:0]  seg_o           // Seven-segment LED cathodes
);

    // Internal Clocks & Resets
    logic core_clk_auto;
    logic disp_clk;
    logic core_clk;
    logic rst_n_debounced;
    logic step_pulse;

    // Core Debug Observation Signals
    logic [31:0] pc_f;
    logic [31:0] pc_d;
    logic [31:0] pc_e;
    logic [31:0] pc_m;
    logic [31:0] pc_w;
    logic        reg_write_w;
    logic [4:0]  rd_w;
    logic [31:0] result_w;
    logic        stall;
    logic        flush;

    // 1. Clock Divider
    clk_divider #(
        .INPUT_FREQ_HZ(50_000_000),
        .CORE_FREQ_HZ (10_000_000), // 10 MHz core clock
        .DISP_FREQ_HZ (1_000)       // 1 kHz display refresh
    ) u_clk_divider (
        .clk_i      (board_clk_i),
        .rst_ni     (btn_rst_ni),
        .core_clk_o (core_clk_auto),
        .disp_clk_o (disp_clk)
    );

    // 2. Debouncers for Reset and Step Button
    debouncer u_btn_rst_debouncer (
        .clk_i        (board_clk_i),
        .rst_ni       (1'b1),
        .btn_i        (btn_rst_ni),
        .btn_state_o  (rst_n_debounced),
        .btn_posedge_o()
    );

    debouncer u_btn_step_debouncer (
        .clk_i        (board_clk_i),
        .rst_ni       (rst_n_debounced),
        .btn_i        (btn_step_i),
        .btn_state_o  (),
        .btn_posedge_o(step_pulse)
    );

    // 3. Execution Clock Selection (Continuous 10MHz vs Manual Single-Step)
    assign core_clk = (sw_step_mode_i) ? core_clk_auto : step_pulse;

    // 4. RV32I Processor System
    rv32i_top u_proc_top (
        .clk_i              (core_clk),
        .rst_ni             (rst_n_debounced),
        .debug_pc_f_o       (pc_f),
        .debug_pc_d_o       (pc_d),
        .debug_pc_e_o       (pc_e),
        .debug_pc_m_o       (pc_m),
        .debug_pc_w_o       (pc_w),
        .debug_reg_write_w_o(reg_write_w),
        .debug_rd_w_o       (rd_w),
        .debug_result_w_o   (result_w),
        .debug_stall_o      (stall),
        .debug_flush_o      (flush)
    );

    // 5. Seven-Segment Multiplexed Display Selection
    logic [15:0] hex_to_display;
    always_comb begin
        case (sw_disp_sel_i)
            2'b00: hex_to_display = pc_f[15:0];       // Lower 16-bits of current PC
            2'b01: hex_to_display = pc_f[31:16];      // Upper 16-bits of current PC
            2'b10: hex_to_display = result_w[15:0];   // Lower 16-bits of Writeback result
            2'b11: hex_to_display = result_w[31:16];  // Upper 16-bits of Writeback result
        endcase
    end

    seven_seg_controller u_seven_seg (
        .clk_1khz_i(disp_clk),
        .rst_ni    (rst_n_debounced),
        .hex_data_i(hex_to_display),
        .anode_o   (anode_o),
        .seg_o     (seg_o)
    );

    // 6. Diagnostic Status LEDs
    assign led_o[0] = reg_write_w;          // LED0: Register write active
    assign led_o[1] = stall;                // LED1: Load-use hazard stall active
    assign led_o[2] = flush;                // LED2: Branch/jump flush active
    assign led_o[3] = (rd_w != 5'd0);       // LED3: Target register non-zero
    assign led_o[4] = core_clk_auto;        // LED4: Clock heartbeat
    assign led_o[5] = sw_step_mode_i;       // LED5: Continuous run mode indicator
    assign led_o[6] = (pc_f == 32'b0);      // LED6: Boot / reset state
    assign led_o[7] = rst_n_debounced;      // LED7: Reset status (high when operational)

endmodule: spartan6_top

`endif

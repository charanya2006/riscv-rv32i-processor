//=============================================================================
// File: execute_stage.sv
// Description: Execute (EX) stage of the 5-stage RV32I pipeline.
//              Contains Forwarding Multiplexers, ALU, Branch Unit,
//              and Branch/Jump Target Address Adder.
//=============================================================================

`ifndef EXECUTE_STAGE_SV
`define EXECUTE_STAGE_SV

`include "rv32i_pkg.sv"
`include "alu.sv"
`include "branch_unit.sv"

module execute_stage (
    input  rv32i_pkg::ctrl_signals_t ctrl_e_i,
    input  logic [31:0]              rd1_e_i,
    input  logic [31:0]              rd2_e_i,
    input  logic [31:0]              imm_ext_e_i,
    input  logic [31:0]              pc_e_i,
    input  logic [31:0]              pc_plus4_e_i,

    // Forwarded values from MEM and WB stages
    input  logic [31:0]              alu_result_m_i,
    input  logic [31:0]              result_w_i,
    input  rv32i_pkg::forward_e      forward_a_e_i,
    input  rv32i_pkg::forward_e      forward_b_e_i,

    // Outputs to EX/MEM pipeline register
    output logic [31:0]              alu_result_e_o,
    output logic [31:0]              write_data_e_o,

    // Branch / Jump control to Fetch and Hazard Units
    output logic                     pc_src_e_o,
    output logic [31:0]              pc_target_e_o
);

    import rv32i_pkg::*;

    logic [31:0] src_a_fwd;
    logic [31:0] src_b_fwd;
    logic [31:0] alu_in_a;
    logic [31:0] alu_in_b;
    logic        branch_taken;
    logic [31:0] branch_pc_target;
    logic [31:0] jalr_target;

    // 1. Forwarding Mux for Operand A
    always_comb begin
        case (forward_a_e_i)
            FWD_NONE: src_a_fwd = rd1_e_i;
            FWD_WB:   src_a_fwd = result_w_i;
            FWD_MEM:  src_a_fwd = alu_result_m_i;
            default:  src_a_fwd = rd1_e_i;
        endcase
    end

    // 2. Forwarding Mux for Operand B
    always_comb begin
        case (forward_b_e_i)
            FWD_NONE: src_b_fwd = rd2_e_i;
            FWD_WB:   src_b_fwd = result_w_i;
            FWD_MEM:  src_b_fwd = alu_result_m_i;
            default:  src_b_fwd = rd2_e_i;
        endcase
    end

    assign write_data_e_o = src_b_fwd;

    // 3. ALU Input A Multiplexer (Register / Forwarded vs PC)
    assign alu_in_a = (ctrl_e_i.alu_src_a == ALU_SRC_A_PC) ? pc_e_i : src_a_fwd;

    // 4. ALU Input B Multiplexer (Register / Forwarded vs Immediate)
    assign alu_in_b = (ctrl_e_i.alu_src_b == ALU_SRC_B_IMM) ? imm_ext_e_i : src_b_fwd;

    // 5. ALU Instantiation
    alu u_alu (
        .a_i        (alu_in_a),
        .b_i        (alu_in_b),
        .alu_op_i   (ctrl_e_i.alu_op),
        .result_o   (alu_result_e_o),
        .zero_o     (),
        .negative_o (),
        .carry_o    (),
        .overflow_o ()
    );

    // 6. Branch Condition Unit
    branch_unit u_branch_unit (
        .src_a_i       (src_a_fwd),
        .src_b_i       (src_b_fwd),
        .branch_type_i (ctrl_e_i.branch_type),
        .branch_en_i   (ctrl_e_i.branch),
        .branch_taken_o(branch_taken)
    );

    // 7. Target Address Calculation
    assign branch_pc_target = pc_e_i + imm_ext_e_i;
    assign jalr_target = (src_a_fwd + imm_ext_e_i) & ~32'd1;

    assign pc_target_e_o = (ctrl_e_i.jalr) ? jalr_target : branch_pc_target;
    assign pc_src_e_o = ctrl_e_i.jump || (ctrl_e_i.branch && branch_taken);

endmodule: execute_stage

`endif

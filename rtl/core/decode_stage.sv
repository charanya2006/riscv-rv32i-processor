//=============================================================================
// File: decode_stage.sv
// Description: Instruction Decode (ID) stage of the 5-stage RV32I pipeline.
//              Contains Control Unit, Register File, and Immediate Generator.
//=============================================================================

`ifndef DECODE_STAGE_SV
`define DECODE_STAGE_SV

`include "rv32i_pkg.sv"
`include "control_unit.sv"
`include "register_file.sv"
`include "imm_gen.sv"

module decode_stage (
    input  logic                   clk_i,
    input  logic                   rst_ni,
    input  logic [31:0]            instr_d_i,
    input  logic [31:0]            pc_d_i,
    input  logic [31:0]            pc_plus4_d_i,

    // Writeback interface from WB stage
    input  logic                   reg_write_w_i,
    input  logic [4:0]             rd_w_i,
    input  logic [31:0]            result_w_i,

    // Decoded control signals & operands for pipeline
    output rv32i_pkg::ctrl_signals_t ctrl_d_o,
    output logic [31:0]            rd1_d_o,
    output logic [31:0]            rd2_d_o,
    output logic [31:0]            imm_ext_d_o,
    output logic [4:0]             rs1_d_o,
    output logic [4:0]             rs2_d_o,
    output logic [4:0]             rd_d_o,
    output logic                   rs1_used_d_o,
    output logic                   rs2_used_d_o,
    output logic                   illegal_instr_d_o
);

    import rv32i_pkg::*;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    imm_src_e   imm_src;

    // Field slicing per RISC-V specification
    assign opcode = instr_d_i[6:0];
    assign rd_d_o = instr_d_i[11:7];
    assign funct3 = instr_d_i[14:12];
    assign rs1_d_o= instr_d_i[19:15];
    assign rs2_d_o= instr_d_i[24:20];
    assign funct7 = instr_d_i[31:25];

    // Identify which instructions consume rs1 / rs2 to avoid false stalls
    always_comb begin
        case (opcode)
            OPCODE_R_TYPE: begin
                rs1_used_d_o = 1'b1;
                rs2_used_d_o = 1'b1;
            end
            OPCODE_I_TYPE, OPCODE_LOAD, OPCODE_JALR: begin
                rs1_used_d_o = 1'b1;
                rs2_used_d_o = 1'b0;
            end
            OPCODE_STORE, OPCODE_BRANCH: begin
                rs1_used_d_o = 1'b1;
                rs2_used_d_o = 1'b1;
            end
            OPCODE_LUI, OPCODE_AUIPC, OPCODE_JAL: begin
                rs1_used_d_o = 1'b0;
                rs2_used_d_o = 1'b0;
            end
            default: begin
                rs1_used_d_o = 1'b0;
                rs2_used_d_o = 1'b0;
            end
        endcase
    end

    // Control Unit
    control_unit u_control (
        .opcode_i        (opcode),
        .funct3_i        (funct3),
        .funct7_i        (funct7),
        .ctrl_o          (ctrl_d_o),
        .imm_src_o       (imm_src),
        .illegal_instr_o (illegal_instr_d_o)
    );

    // Register File (x0 hardwired to 0, dual-read, single-write with bypass)
    register_file u_rf (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .we_i    (reg_write_w_i),
        .waddr_i (rd_w_i),
        .wdata_i (result_w_i),
        .raddr1_i(rs1_d_o),
        .rdata1_o(rd1_d_o),
        .raddr2_i(rs2_d_o),
        .rdata2_o(rd2_d_o)
    );

    // Immediate Generator
    imm_gen u_imm_gen (
        .instr_i   (instr_d_i),
        .imm_src_i (imm_src),
        .imm_o     (imm_ext_d_o)
    );

endmodule: decode_stage

`endif

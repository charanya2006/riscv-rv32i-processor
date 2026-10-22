//=============================================================================
// File: imm_gen.sv
// Description: Immediate Generator for RISC-V 32-bit base instruction formats:
//              I-type, S-type, B-type, U-type, and J-type.
//=============================================================================

`ifndef IMM_GEN_SV
`define IMM_GEN_SV

`include "rv32i_pkg.sv"

module imm_gen (
    input  logic [31:0]          instr_i,
    input  rv32i_pkg::imm_src_e  imm_src_i,
    output logic [31:0]          imm_o
);

    import rv32i_pkg::*;

    always_comb begin
        case (imm_src_i)
            IMM_I: imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            IMM_S: imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            IMM_B: imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            IMM_U: imm_o = {instr_i[31:12], 12'b0};
            IMM_J: imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            default: imm_o = 32'b0;
        endcase
    end

endmodule: imm_gen

`endif

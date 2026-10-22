//=============================================================================
// File: control_unit.sv
// Description: Main Decoder & ALU Decoder for RV32I Processor.
//              Generates all control signals for the 5-stage pipeline.
//=============================================================================

`ifndef CONTROL_UNIT_SV
`define CONTROL_UNIT_SV

`include "rv32i_pkg.sv"

module control_unit (
    input  logic                   [6:0] opcode_i,
    input  logic                   [2:0] funct3_i,
    input  logic                   [6:0] funct7_i,
    output rv32i_pkg::ctrl_signals_t     ctrl_o,
    output rv32i_pkg::imm_src_e          imm_src_o,
    output logic                         illegal_instr_o
);

    import rv32i_pkg::*;

    always_comb begin
        // Default control signal assignments (NOP state)
        ctrl_o.reg_write   = 1'b0;
        ctrl_o.result_src  = RES_ALU;
        ctrl_o.mem_write   = 1'b0;
        ctrl_o.mem_read    = 1'b0;
        ctrl_o.branch      = 1'b0;
        ctrl_o.branch_type = BR_BEQ;
        ctrl_o.jump        = 1'b0;
        ctrl_o.jalr        = 1'b0;
        ctrl_o.alu_op      = ALU_ADD;
        ctrl_o.alu_src_a   = ALU_SRC_A_RS1;
        ctrl_o.alu_src_b   = ALU_SRC_B_RS2;
        ctrl_o.load_type   = LD_LW;
        ctrl_o.store_type  = ST_SW;
        imm_src_o          = IMM_I;
        illegal_instr_o    = 1'b0;

        case (opcode_i)
            //-----------------------------------------------------------------
            // R-Type Instructions (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
            //-----------------------------------------------------------------
            OPCODE_R_TYPE: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.result_src= RES_ALU;
                ctrl_o.alu_src_a = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b = ALU_SRC_B_RS2;
                case (funct3_i)
                    3'b000: begin
                        if (funct7_i[5]) ctrl_o.alu_op = ALU_SUB;
                        else             ctrl_o.alu_op = ALU_ADD;
                    end
                    3'b001: ctrl_o.alu_op = ALU_SLL;
                    3'b010: ctrl_o.alu_op = ALU_SLT;
                    3'b011: ctrl_o.alu_op = ALU_SLTU;
                    3'b100: ctrl_o.alu_op = ALU_XOR;
                    3'b101: begin
                        if (funct7_i[5]) ctrl_o.alu_op = ALU_SRA;
                        else             ctrl_o.alu_op = ALU_SRL;
                    end
                    3'b110: ctrl_o.alu_op = ALU_OR;
                    3'b111: ctrl_o.alu_op = ALU_AND;
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //-----------------------------------------------------------------
            // I-Type ALU Instructions (ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI)
            //-----------------------------------------------------------------
            OPCODE_I_TYPE: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.result_src= RES_ALU;
                ctrl_o.alu_src_a = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b = ALU_SRC_B_IMM;
                imm_src_o        = IMM_I;
                case (funct3_i)
                    3'b000: ctrl_o.alu_op = ALU_ADD;
                    3'b001: ctrl_o.alu_op = ALU_SLL;
                    3'b010: ctrl_o.alu_op = ALU_SLT;
                    3'b011: ctrl_o.alu_op = ALU_SLTU;
                    3'b100: ctrl_o.alu_op = ALU_XOR;
                    3'b101: begin
                        if (funct7_i[5]) ctrl_o.alu_op = ALU_SRA;
                        else             ctrl_o.alu_op = ALU_SRL;
                    end
                    3'b110: ctrl_o.alu_op = ALU_OR;
                    3'b111: ctrl_o.alu_op = ALU_AND;
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //-----------------------------------------------------------------
            // Load Instructions (LB, LH, LW, LBU, LHU)
            //-----------------------------------------------------------------
            OPCODE_LOAD: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.result_src= RES_MEM;
                ctrl_o.mem_read  = 1'b1;
                ctrl_o.alu_src_a = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b = ALU_SRC_B_IMM;
                ctrl_o.alu_op    = ALU_ADD;
                imm_src_o        = IMM_I;
                case (funct3_i)
                    3'b000: ctrl_o.load_type = LD_LB;
                    3'b001: ctrl_o.load_type = LD_LH;
                    3'b010: ctrl_o.load_type = LD_LW;
                    3'b100: ctrl_o.load_type = LD_LBU;
                    3'b101: ctrl_o.load_type = LD_LHU;
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //-----------------------------------------------------------------
            // Store Instructions (SB, SH, SW)
            //-----------------------------------------------------------------
            OPCODE_STORE: begin
                ctrl_o.mem_write = 1'b1;
                ctrl_o.alu_src_a = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b = ALU_SRC_B_IMM;
                ctrl_o.alu_op    = ALU_ADD;
                imm_src_o        = IMM_S;
                case (funct3_i)
                    3'b000: ctrl_o.store_type = ST_SB;
                    3'b001: ctrl_o.store_type = ST_SH;
                    3'b010: ctrl_o.store_type = ST_SW;
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //-----------------------------------------------------------------
            // Branch Instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            //-----------------------------------------------------------------
            OPCODE_BRANCH: begin
                ctrl_o.branch      = 1'b1;
                ctrl_o.alu_src_a   = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b   = ALU_SRC_B_RS2;
                ctrl_o.alu_op      = ALU_SUB;
                imm_src_o          = IMM_B;
                case (funct3_i)
                    3'b000: ctrl_o.branch_type = BR_BEQ;
                    3'b001: ctrl_o.branch_type = BR_BNE;
                    3'b100: ctrl_o.branch_type = BR_BLT;
                    3'b101: ctrl_o.branch_type = BR_BGE;
                    3'b110: ctrl_o.branch_type = BR_BLTU;
                    3'b111: ctrl_o.branch_type = BR_BGEU;
                    default: illegal_instr_o = 1'b1;
                endcase
            end

            //-----------------------------------------------------------------
            // JAL (Jump and Link)
            //-----------------------------------------------------------------
            OPCODE_JAL: begin
                ctrl_o.reg_write  = 1'b1;
                ctrl_o.result_src = RES_PC4;
                ctrl_o.jump       = 1'b1;
                ctrl_o.alu_src_a  = ALU_SRC_A_PC;
                ctrl_o.alu_src_b  = ALU_SRC_B_IMM;
                ctrl_o.alu_op     = ALU_ADD;
                imm_src_o         = IMM_J;
            end

            //-----------------------------------------------------------------
            // JALR (Jump and Link Register)
            //-----------------------------------------------------------------
            OPCODE_JALR: begin
                ctrl_o.reg_write  = 1'b1;
                ctrl_o.result_src = RES_PC4;
                ctrl_o.jump       = 1'b1;
                ctrl_o.jalr       = 1'b1;
                ctrl_o.alu_src_a  = ALU_SRC_A_RS1;
                ctrl_o.alu_src_b  = ALU_SRC_B_IMM;
                ctrl_o.alu_op     = ALU_ADD;
                imm_src_o         = IMM_I;
            end

            //-----------------------------------------------------------------
            // LUI (Load Upper Immediate)
            //-----------------------------------------------------------------
            OPCODE_LUI: begin
                ctrl_o.reg_write  = 1'b1;
                ctrl_o.result_src = RES_ALU;
                ctrl_o.alu_src_b  = ALU_SRC_B_IMM;
                ctrl_o.alu_op     = ALU_PASS_B;
                imm_src_o         = IMM_U;
            end

            //-----------------------------------------------------------------
            // AUIPC (Add Upper Immediate to PC)
            //-----------------------------------------------------------------
            OPCODE_AUIPC: begin
                ctrl_o.reg_write  = 1'b1;
                ctrl_o.result_src = RES_ALU;
                ctrl_o.alu_src_a  = ALU_SRC_A_PC;
                ctrl_o.alu_src_b  = ALU_SRC_B_IMM;
                ctrl_o.alu_op     = ALU_ADD;
                imm_src_o         = IMM_U;
            end

            //-----------------------------------------------------------------
            // FENCE / SYSTEM / NOP
            //-----------------------------------------------------------------
            OPCODE_FENCE, OPCODE_SYSTEM: begin
                ctrl_o.reg_write = 1'b0;
            end

            default: begin
                illegal_instr_o = 1'b1;
            end
        endcase
    end

endmodule: control_unit

`endif

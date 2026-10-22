//=============================================================================
// File: rv32i_pkg.sv
// Description: Package containing types, enums, opcodes, and control structs
//              for the 5-Stage Pipelined RV32I Processor.
// Target: Synthesizable SystemVerilog (Xilinx Vivado, Spartan-6, OpenLane/OpenROAD)
//=============================================================================

`ifndef RV32I_PKG_SV
`define RV32I_PKG_SV

package rv32i_pkg;

    // Standard RISC-V 32-bit parameters
    localparam int XLEN = 32;
    localparam int REG_ADDR_WIDTH = 5;

    // 7-bit RISC-V Base Opcodes
    typedef enum logic [6:0] {
        OPCODE_R_TYPE   = 7'b0110011, // R-type ALU: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
        OPCODE_I_TYPE   = 7'b0010011, // I-type ALU: ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI
        OPCODE_LOAD     = 7'b0000011, // Load: LB, LH, LW, LBU, LHU
        OPCODE_STORE    = 7'b0100011, // Store: SB, SH, SW
        OPCODE_BRANCH   = 7'b1100011, // Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
        OPCODE_JAL      = 7'b1101111, // Jump and Link
        OPCODE_JALR     = 7'b1100111, // Jump and Link Register
        OPCODE_LUI      = 7'b0110111, // Load Upper Immediate
        OPCODE_AUIPC    = 7'b0010111, // Add Upper Immediate to PC
        OPCODE_SYSTEM   = 7'b1110011, // System / ECALL / EBREAK
        OPCODE_FENCE    = 7'b0001111  // Memory Fence / NOP
    } opcode_e;

    // ALU Operation Codes
    typedef enum logic [3:0] {
        ALU_ADD   = 4'b0000,
        ALU_SUB   = 4'b0001,
        ALU_SLL   = 4'b0010,
        ALU_SLT   = 4'b0011,
        ALU_SLTU  = 4'b0100,
        ALU_XOR   = 4'b0101,
        ALU_SRL   = 4'b0110,
        ALU_SRA   = 4'b0111,
        ALU_OR    = 4'b1000,
        ALU_AND   = 4'b1001,
        ALU_PASS_B= 4'b1010
    } alu_op_e;

    // Branch condition types (based on funct3)
    typedef enum logic [2:0] {
        BR_BEQ  = 3'b000,
        BR_BNE  = 3'b001,
        BR_BLT  = 3'b100,
        BR_BGE  = 3'b101,
        BR_BLTU = 3'b110,
        BR_BGEU = 3'b111
    } branch_type_e;

    // Load instruction width & sign extension (based on funct3)
    typedef enum logic [2:0] {
        LD_LB  = 3'b000,
        LD_LH  = 3'b001,
        LD_LW  = 3'b010,
        LD_LBU = 3'b100,
        LD_LHU = 3'b101
    } load_type_e;

    // Store instruction width (based on funct3)
    typedef enum logic [1:0] {
        ST_SB  = 2'b00,
        ST_SH  = 2'b01,
        ST_SW  = 2'b10
    } store_type_e;

    // Result Source Mux Select in Writeback Stage
    typedef enum logic [1:0] {
        RES_ALU  = 2'b00,
        RES_MEM  = 2'b01,
        RES_PC4  = 2'b10,
        RES_IMM  = 2'b11
    } result_src_e;

    // ALU Operand A Selection
    typedef enum logic {
        ALU_SRC_A_RS1 = 1'b0,
        ALU_SRC_A_PC  = 1'b1
    } alu_src_a_e;

    // ALU Operand B Selection
    typedef enum logic {
        ALU_SRC_B_RS2 = 1'b0,
        ALU_SRC_B_IMM = 1'b1
    } alu_src_b_e;

    // Forwarding Mux Select
    typedef enum logic [1:0] {
        FWD_NONE = 2'b00, // Register file output
        FWD_WB   = 2'b01, // Forward from WB stage (ResultW)
        FWD_MEM  = 2'b10  // Forward from MEM stage (ALU_ResultM)
    } forward_e;

    // Immediate format select
    typedef enum logic [2:0] {
        IMM_I = 3'b000,
        IMM_S = 3'b001,
        IMM_B = 3'b010,
        IMM_U = 3'b011,
        IMM_J = 3'b100
    } imm_src_e;

    // Control Signals Bundle
    typedef struct packed {
        logic         reg_write;
        result_src_e  result_src;
        logic         mem_write;
        logic         mem_read;
        logic         branch;
        branch_type_e branch_type;
        logic         jump;
        logic         jalr;
        alu_op_e      alu_op;
        alu_src_a_e   alu_src_a;
        alu_src_b_e   alu_src_b;
        load_type_e   load_type;
        store_type_e  store_type;
    } ctrl_signals_t;

endpackage: rv32i_pkg

`endif

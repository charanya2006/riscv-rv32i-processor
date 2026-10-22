//=============================================================================
// File: alu.sv
// Description: Synthesizable 32-bit Arithmetic Logic Unit for RV32I
// Supports: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, PASS_B
//=============================================================================

`ifndef ALU_SV
`define ALU_SV

`include "rv32i_pkg.sv"

module alu (
    input  logic [31:0]        a_i,
    input  logic [31:0]        b_i,
    input  rv32i_pkg::alu_op_e alu_op_i,
    output logic [31:0]        result_o,
    output logic               zero_o,
    output logic               negative_o,
    output logic               carry_o,
    output logic               overflow_o
);

    import rv32i_pkg::*;

    logic [32:0] sum_extended;
    logic [4:0]  shamt;

    assign shamt = b_i[4:0];

    // Compute adder/subtractor result with carry-out
    always_comb begin
        if (alu_op_i == ALU_SUB || alu_op_i == ALU_SLT || alu_op_i == ALU_SLTU) begin
            sum_extended = {1'b0, a_i} + {1'b0, ~b_i} + 33'd1;
        end else begin
            sum_extended = {1'b0, a_i} + {1'b0, b_i};
        end
    end

    // ALU multiplexer
    always_comb begin
        case (alu_op_i)
            ALU_ADD:    result_o = sum_extended[31:0];
            ALU_SUB:    result_o = sum_extended[31:0];
            ALU_SLL:    result_o = a_i << shamt;
            ALU_SLT:    result_o = {31'b0, ($signed(a_i) < $signed(b_i)) ? 1'b1 : 1'b0};
            ALU_SLTU:   result_o = {31'b0, (a_i < b_i) ? 1'b1 : 1'b0};
            ALU_XOR:    result_o = a_i ^ b_i;
            ALU_SRL:    result_o = a_i >> shamt;
            ALU_SRA:    result_o = $signed(a_i) >>> shamt;
            ALU_OR:     result_o = a_i | b_i;
            ALU_AND:    result_o = a_i & b_i;
            ALU_PASS_B: result_o = b_i;
            default:    result_o = 32'b0;
        endcase
    end

    // Status flags
    assign zero_o      = (result_o == 32'b0);
    assign negative_o  = result_o[31];
    assign carry_o     = sum_extended[32];
    assign overflow_o  = (a_i[31] == (alu_op_i == ALU_SUB ? ~b_i[31] : b_i[31])) && 
                         (result_o[31] != a_i[31]);

endmodule: alu

`endif

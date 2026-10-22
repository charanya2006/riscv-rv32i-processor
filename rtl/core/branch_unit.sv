//=============================================================================
// File: branch_unit.sv
// Description: Evaluates branch conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//=============================================================================

`ifndef BRANCH_UNIT_SV
`define BRANCH_UNIT_SV

`include "rv32i_pkg.sv"

module branch_unit (
    input  logic [31:0]             src_a_i,
    input  logic [31:0]             src_b_i,
    input  rv32i_pkg::branch_type_e branch_type_i,
    input  logic                    branch_en_i,
    output logic                    branch_taken_o
);

    import rv32i_pkg::*;

    always_comb begin
        if (!branch_en_i) begin
            branch_taken_o = 1'b0;
        end else begin
            case (branch_type_i)
                BR_BEQ:  branch_taken_o = (src_a_i == src_b_i);
                BR_BNE:  branch_taken_o = (src_a_i != src_b_i);
                BR_BLT:  branch_taken_o = ($signed(src_a_i) < $signed(src_b_i));
                BR_BGE:  branch_taken_o = ($signed(src_a_i) >= $signed(src_b_i));
                BR_BLTU: branch_taken_o = (src_a_i < src_b_i);
                BR_BGEU: branch_taken_o = (src_a_i >= src_b_i);
                default: branch_taken_o = 1'b0;
            endcase
        end
    end

endmodule: branch_unit

`endif

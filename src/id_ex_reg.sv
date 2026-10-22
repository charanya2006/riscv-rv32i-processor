//=============================================================================
// File: id_ex_reg.sv
// Description: ID/EX Pipeline Register. Holds operands and control signals
//              between Decode and Execute stages. Supports synchronous flush.
//=============================================================================

`ifndef ID_EX_REG_SV
`define ID_EX_REG_SV

`include "rv32i_pkg.sv"

module id_ex_reg (
    input  logic                   clk_i,
    input  logic                   rst_ni,
    input  logic                   flush_e_i,

    // Inputs from ID Stage
    input  rv32i_pkg::ctrl_signals_t ctrl_d_i,
    input  logic [31:0]            rd1_d_i,
    input  logic [31:0]            rd2_d_i,
    input  logic [31:0]            imm_ext_d_i,
    input  logic [31:0]            pc_d_i,
    input  logic [31:0]            pc_plus4_d_i,
    input  logic [4:0]             rs1_d_i,
    input  logic [4:0]             rs2_d_i,
    input  logic [4:0]             rd_d_i,

    // Registered outputs to EX Stage
    output rv32i_pkg::ctrl_signals_t ctrl_e_o,
    output logic [31:0]            rd1_e_o,
    output logic [31:0]            rd2_e_o,
    output logic [31:0]            imm_ext_e_o,
    output logic [31:0]            pc_e_o,
    output logic [31:0]            pc_plus4_e_o,
    output logic [4:0]             rs1_e_o,
    output logic [4:0]             rs2_e_o,
    output logic [4:0]             rd_e_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_e_o     <= '0;
            rd1_e_o      <= 32'b0;
            rd2_e_o      <= 32'b0;
            imm_ext_e_o  <= 32'b0;
            pc_e_o       <= 32'b0;
            pc_plus4_e_o <= 32'b0;
            rs1_e_o      <= 5'b0;
            rs2_e_o      <= 5'b0;
            rd_e_o       <= 5'b0;
        end else if (flush_e_i) begin
            ctrl_e_o     <= '0;
            rd1_e_o      <= 32'b0;
            rd2_e_o      <= 32'b0;
            imm_ext_e_o  <= 32'b0;
            pc_e_o       <= 32'b0;
            pc_plus4_e_o <= 32'b0;
            rs1_e_o      <= 5'b0;
            rs2_e_o      <= 5'b0;
            rd_e_o       <= 5'b0;
        end else begin
            ctrl_e_o     <= ctrl_d_i;
            rd1_e_o      <= rd1_d_i;
            rd2_e_o      <= rd2_d_i;
            imm_ext_e_o  <= imm_ext_d_i;
            pc_e_o       <= pc_d_i;
            pc_plus4_e_o <= pc_plus4_d_i;
            rs1_e_o      <= rs1_d_i;
            rs2_e_o      <= rs2_d_i;
            rd_e_o       <= rd_d_i;
        end
    end

endmodule: id_ex_reg

`endif

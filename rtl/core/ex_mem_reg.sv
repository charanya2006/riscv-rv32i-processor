//=============================================================================
// File: ex_mem_reg.sv
// Description: EX/MEM Pipeline Register. Holds operands, ALU result,
//              and control signals between Execute and Memory stages.
//=============================================================================

`ifndef EX_MEM_REG_SV
`define EX_MEM_REG_SV

`include "rv32i_pkg.sv"

module ex_mem_reg (
    input  logic                   clk_i,
    input  logic                   rst_ni,

    // Inputs from EX Stage
    input  rv32i_pkg::ctrl_signals_t ctrl_e_i,
    input  logic [31:0]            alu_result_e_i,
    input  logic [31:0]            write_data_e_i,
    input  logic [4:0]             rd_e_i,
    input  logic [4:0]             rs2_e_i,
    input  logic [31:0]            pc_plus4_e_i,

    // Registered outputs to MEM Stage
    output rv32i_pkg::ctrl_signals_t ctrl_m_o,
    output logic [31:0]            alu_result_m_o,
    output logic [31:0]            write_data_m_o,
    output logic [4:0]             rd_m_o,
    output logic [4:0]             rs2_m_o,
    output logic [31:0]            pc_plus4_m_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_m_o       <= '0;
            alu_result_m_o <= 32'b0;
            write_data_m_o <= 32'b0;
            rd_m_o         <= 5'b0;
            rs2_m_o        <= 5'b0;
            pc_plus4_m_o   <= 32'b0;
        end else begin
            ctrl_m_o       <= ctrl_e_i;
            alu_result_m_o <= alu_result_e_i;
            write_data_m_o <= write_data_e_i;
            rd_m_o         <= rd_e_i;
            rs2_m_o        <= rs2_e_i;
            pc_plus4_m_o   <= pc_plus4_e_i;
        end
    end

endmodule: ex_mem_reg

`endif

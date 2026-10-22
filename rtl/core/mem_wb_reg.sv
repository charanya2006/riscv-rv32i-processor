//=============================================================================
// File: mem_wb_reg.sv
// Description: MEM/WB Pipeline Register. Holds memory data, ALU result,
//              and control signals between Memory and Writeback stages.
//=============================================================================

`ifndef MEM_WB_REG_SV
`define MEM_WB_REG_SV

`include "rv32i_pkg.sv"

module mem_wb_reg (
    input  logic                   clk_i,
    input  logic                   rst_ni,

    // Inputs from MEM Stage
    input  rv32i_pkg::ctrl_signals_t ctrl_m_i,
    input  logic [31:0]            alu_result_m_i,
    input  logic [31:0]            read_data_m_i,
    input  logic [4:0]             rd_m_i,
    input  logic [31:0]            pc_plus4_m_i,

    // Registered outputs to WB Stage
    output rv32i_pkg::ctrl_signals_t ctrl_w_o,
    output logic [31:0]            alu_result_w_o,
    output logic [31:0]            read_data_w_o,
    output logic [4:0]             rd_w_o,
    output logic [31:0]            pc_plus4_w_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ctrl_w_o       <= '0;
            alu_result_w_o <= 32'b0;
            read_data_w_o  <= 32'b0;
            rd_w_o         <= 5'b0;
            pc_plus4_w_o   <= 32'b0;
        end else begin
            ctrl_w_o       <= ctrl_m_i;
            alu_result_w_o <= alu_result_m_i;
            read_data_w_o  <= read_data_m_i;
            rd_w_o         <= rd_m_i;
            pc_plus4_w_o   <= pc_plus4_m_i;
        end
    end

endmodule: mem_wb_reg

`endif

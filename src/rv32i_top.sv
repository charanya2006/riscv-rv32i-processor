//=============================================================================
// File: rv32i_top.sv
// Description: Top-Level RV32I Processor System integrating Core,
//              Instruction Memory, and Data Memory.
//=============================================================================

`ifndef RV32I_TOP_SV
`define RV32I_TOP_SV

`include "rv32i_pkg.sv"
`include "rv32i_core.sv"
`include "instruction_mem.sv"
`include "data_mem.sv"

module rv32i_top #(
    parameter IMEM_HEX = "",
    parameter DMEM_HEX = "",
    parameter int MEM_DEPTH = 1024
)(
    input  logic        clk_i,
    input  logic        rst_ni,

    // Core Debug / Observation Ports
    output logic [31:0] debug_pc_f_o,
    output logic [31:0] debug_pc_d_o,
    output logic [31:0] debug_pc_e_o,
    output logic [31:0] debug_pc_m_o,
    output logic [31:0] debug_pc_w_o,
    output logic        debug_reg_write_w_o,
    output logic [4:0]  debug_rd_w_o,
    output logic [31:0] debug_result_w_o,
    output logic        debug_stall_o,
    output logic        debug_flush_o
);

    // Memory interconnect wires
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic        dmem_wen;
    logic        dmem_ren;
    logic [31:0] dmem_rdata;

    // RV32I Core
    rv32i_core u_core (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .imem_addr_o        (imem_addr),
        .imem_rdata_i       (imem_rdata),
        .dmem_addr_o        (dmem_addr),
        .dmem_wdata_o       (dmem_wdata),
        .dmem_wmask_o       (dmem_wmask),
        .dmem_wen_o         (dmem_wen),
        .dmem_ren_o         (dmem_ren),
        .dmem_rdata_i       (dmem_rdata),
        .debug_pc_f_o       (debug_pc_f_o),
        .debug_pc_d_o       (debug_pc_d_o),
        .debug_pc_e_o       (debug_pc_e_o),
        .debug_pc_m_o       (debug_pc_m_o),
        .debug_pc_w_o       (debug_pc_w_o),
        .debug_reg_write_w_o(debug_reg_write_w_o),
        .debug_rd_w_o       (debug_rd_w_o),
        .debug_result_w_o   (debug_result_w_o),
        .debug_stall_o      (debug_stall_o),
        .debug_flush_o      (debug_flush_o)
    );

    // Instruction Memory
    instruction_mem #(
        .MEM_DEPTH(MEM_DEPTH),
        .HEX_FILE (IMEM_HEX)
    ) u_imem (
        .clk_i  (clk_i),
        .addr_i (imem_addr),
        .rdata_o(imem_rdata)
    );

    // Data Memory
    data_mem #(
        .MEM_DEPTH(MEM_DEPTH),
        .HEX_FILE (DMEM_HEX)
    ) u_dmem (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .addr_i (dmem_addr),
        .wdata_i(dmem_wdata),
        .wmask_i(dmem_wmask),
        .wen_i  (dmem_wen),
        .ren_i  (dmem_ren),
        .rdata_o(dmem_rdata)
    );

endmodule: rv32i_top

`endif

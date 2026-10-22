//=============================================================================
// File: rv32i_core.sv
// Description: Top-level synthesizable 5-Stage Pipelined RV32I Processor Core.
//              Integrates IF, ID, EX, MEM, WB stages, pipeline registers,
//              data forwarding, load-use hazard detection, and branch flushing.
//=============================================================================

`ifndef RV32I_CORE_SV
`define RV32I_CORE_SV

`include "rv32i_pkg.sv"
`include "fetch_stage.sv"
`include "if_id_reg.sv"
`include "decode_stage.sv"
`include "id_ex_reg.sv"
`include "execute_stage.sv"
`include "ex_mem_reg.sv"
`include "memory_stage.sv"
`include "mem_wb_reg.sv"
`include "writeback_stage.sv"
`include "hazard_unit.sv"

module rv32i_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Instruction Memory Interface
    output logic [31:0] imem_addr_o,
    input  logic [31:0] imem_rdata_i,

    // Data Memory Interface
    output logic [31:0] dmem_addr_o,
    output logic [31:0] dmem_wdata_o,
    output logic [3:0]  dmem_wmask_o,
    output logic        dmem_wen_o,
    output logic        dmem_ren_o,
    input  logic [31:0] dmem_rdata_i,

    // Core Status / Debug Visibility
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

    import rv32i_pkg::*;

    //=========================================================================
    // Internal Pipeline Signals
    //=========================================================================

    // Hazard Controls
    forward_e      forward_a_e;
    forward_e      forward_b_e;
    logic          forward_m_b;
    logic          stall_f;
    logic          stall_d;
    logic          flush_d;
    logic          flush_e;

    // Fetch Stage (IF)
    logic [31:0]   pc_f;
    logic [31:0]   pc_plus4_f;

    // Decode Stage (ID)
    logic [31:0]   pc_d;
    logic [31:0]   pc_plus4_d;
    logic [31:0]   instr_d;
    ctrl_signals_t ctrl_d;
    logic [31:0]   rd1_d;
    logic [31:0]   rd2_d;
    logic [31:0]   imm_ext_d;
    logic [4:0]    rs1_d;
    logic [4:0]    rs2_d;
    logic [4:0]    rd_d;
    logic          rs1_used_d;
    logic          rs2_used_d;
    logic          illegal_instr_d;

    // Execute Stage (EX)
    ctrl_signals_t ctrl_e;
    logic [31:0]   rd1_e;
    logic [31:0]   rd2_e;
    logic [31:0]   imm_ext_e;
    logic [31:0]   pc_e;
    logic [31:0]   pc_plus4_e;
    logic [4:0]    rs1_e;
    logic [4:0]    rs2_e;
    logic [4:0]    rd_e;
    logic [31:0]   alu_result_e;
    logic [31:0]   write_data_e;
    logic          pc_src_e;
    logic [31:0]   pc_target_e;

    // Memory Stage (MEM)
    ctrl_signals_t ctrl_m;
    logic [31:0]   alu_result_m;
    logic [31:0]   write_data_m;
    logic [4:0]    rd_m;
    logic [4:0]    rs2_m;
    logic [31:0]   pc_plus4_m;
    logic [31:0]   read_data_m;

    // Writeback Stage (WB)
    ctrl_signals_t ctrl_w;
    logic [31:0]   alu_result_w;
    logic [31:0]   read_data_w;
    logic [4:0]    rd_w;
    logic [31:0]   pc_plus4_w;
    logic          reg_write_w;
    logic [31:0]   result_w;

    // PC propagation registers for full architectural debug tracking
    logic [31:0]   pc_m_reg;
    logic [31:0]   pc_w_reg;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_m_reg <= 32'b0;
            pc_w_reg <= 32'b0;
        end else begin
            pc_m_reg <= pc_e;
            pc_w_reg <= pc_m_reg;
        end
    end

    // Instruction Memory Address Assignment
    assign imem_addr_o = pc_f;

    //=========================================================================
    // 1. Fetch Stage & IF/ID Pipeline Register
    //=========================================================================
    fetch_stage u_fetch_stage (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .stall_f_i    (stall_f),
        .pc_src_e_i   (pc_src_e),
        .pc_target_e_i(pc_target_e),
        .pc_f_o       (pc_f),
        .pc_plus4_f_o (pc_plus4_f)
    );

    if_id_reg u_if_id_reg (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .stall_d_i   (stall_d),
        .flush_d_i   (flush_d),
        .pc_f_i      (pc_f),
        .pc_plus4_f_i(pc_plus4_f),
        .instr_f_i   (imem_rdata_i),
        .pc_d_o      (pc_d),
        .pc_plus4_d_o(pc_plus4_d),
        .instr_d_o   (instr_d)
    );

    //=========================================================================
    // 2. Decode Stage & ID/EX Pipeline Register
    //=========================================================================
    decode_stage u_decode_stage (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .instr_d_i        (instr_d),
        .pc_d_i           (pc_d),
        .pc_plus4_d_i     (pc_plus4_d),
        .reg_write_w_i    (reg_write_w),
        .rd_w_i           (rd_w),
        .result_w_i       (result_w),
        .ctrl_d_o         (ctrl_d),
        .rd1_d_o          (rd1_d),
        .rd2_d_o          (rd2_d),
        .imm_ext_d_o      (imm_ext_d),
        .rs1_d_o          (rs1_d),
        .rs2_d_o          (rs2_d),
        .rd_d_o           (rd_d),
        .rs1_used_d_o     (rs1_used_d),
        .rs2_used_d_o     (rs2_used_d),
        .illegal_instr_d_o(illegal_instr_d)
    );

    id_ex_reg u_id_ex_reg (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .flush_e_i   (flush_e),
        .ctrl_d_i    (ctrl_d),
        .rd1_d_i     (rd1_d),
        .rd2_d_i     (rd2_d),
        .imm_ext_d_i (imm_ext_d),
        .pc_d_i      (pc_d),
        .pc_plus4_d_i(pc_plus4_d),
        .rs1_d_i     (rs1_d),
        .rs2_d_i     (rs2_d),
        .rd_d_i      (rd_d),
        .ctrl_e_o    (ctrl_e),
        .rd1_e_o     (rd1_e),
        .rd2_e_o     (rd2_e),
        .imm_ext_e_o (imm_ext_e),
        .pc_e_o      (pc_e),
        .pc_plus4_e_o(pc_plus4_e),
        .rs1_e_o     (rs1_e),
        .rs2_e_o     (rs2_e),
        .rd_e_o      (rd_e)
    );

    //=========================================================================
    // 3. Execute Stage & EX/MEM Pipeline Register
    //=========================================================================
    execute_stage u_execute_stage (
        .ctrl_e_i      (ctrl_e),
        .rd1_e_i       (rd1_e),
        .rd2_e_i       (rd2_e),
        .imm_ext_e_i   (imm_ext_e),
        .pc_e_i        (pc_e),
        .pc_plus4_e_i  (pc_plus4_e),
        .alu_result_m_i(alu_result_m),
        .result_w_i    (result_w),
        .forward_a_e_i (forward_a_e),
        .forward_b_e_i (forward_b_e),
        .alu_result_e_o(alu_result_e),
        .write_data_e_o(write_data_e),
        .pc_src_e_o    (pc_src_e),
        .pc_target_e_o (pc_target_e)
    );

    ex_mem_reg u_ex_mem_reg (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .ctrl_e_i      (ctrl_e),
        .alu_result_e_i(alu_result_e),
        .write_data_e_i(write_data_e),
        .rd_e_i        (rd_e),
        .rs2_e_i       (rs2_e),
        .pc_plus4_e_i  (pc_plus4_e),
        .ctrl_m_o      (ctrl_m),
        .alu_result_m_o(alu_result_m),
        .write_data_m_o(write_data_m),
        .rd_m_o        (rd_m),
        .rs2_m_o       (rs2_m),
        .pc_plus4_m_o  (pc_plus4_m)
    );

    //=========================================================================
    // 4. Memory Stage & MEM/WB Pipeline Register
    //=========================================================================
    memory_stage u_memory_stage (
        .ctrl_m_i      (ctrl_m),
        .alu_result_m_i(alu_result_m),
        .write_data_m_i(write_data_m),
        .result_w_i    (result_w),
        .forward_m_b_i (forward_m_b),
        .dmem_addr_o   (dmem_addr_o),
        .dmem_wdata_o  (dmem_wdata_o),
        .dmem_wmask_o  (dmem_wmask_o),
        .dmem_wen_o    (dmem_wen_o),
        .dmem_ren_o    (dmem_ren_o),
        .dmem_rdata_i  (dmem_rdata_i),
        .read_data_m_o (read_data_m)
    );

    mem_wb_reg u_mem_wb_reg (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .ctrl_m_i      (ctrl_m),
        .alu_result_m_i(alu_result_m),
        .read_data_m_i (read_data_m),
        .rd_m_i        (rd_m),
        .pc_plus4_m_i  (pc_plus4_m),
        .ctrl_w_o      (ctrl_w),
        .alu_result_w_o(alu_result_w),
        .read_data_w_o (read_data_w),
        .rd_w_o        (rd_w),
        .pc_plus4_w_o  (pc_plus4_w)
    );

    //=========================================================================
    // 5. Writeback Stage
    //=========================================================================
    writeback_stage u_writeback_stage (
        .ctrl_w_i      (ctrl_w),
        .alu_result_w_i(alu_result_w),
        .read_data_w_i (read_data_w),
        .pc_plus4_w_i  (pc_plus4_w),
        .rd_w_i        (rd_w),
        .reg_write_w_o (reg_write_w),
        .rd_w_o        (),
        .result_w_o    (result_w)
    );

    //=========================================================================
    // 6. Hazard & Forwarding Unit
    //=========================================================================
    hazard_unit u_hazard_unit (
        .rs1_d_i      (rs1_d),
        .rs2_d_i      (rs2_d),
        .rs1_used_d_i (rs1_used_d),
        .rs2_used_d_i (rs2_used_d),
        .rs1_e_i      (rs1_e),
        .rs2_e_i      (rs2_e),
        .rd_e_i       (rd_e),
        .mem_read_e_i (ctrl_e.mem_read),
        .pc_src_e_i   (pc_src_e),
        .rd_m_i       (rd_m),
        .rs2_m_i      (rs2_m),
        .reg_write_m_i(ctrl_m.reg_write),
        .mem_write_m_i(ctrl_m.mem_write),
        .rd_w_i       (rd_w),
        .reg_write_w_i(reg_write_w),
        .forward_a_e_o(forward_a_e),
        .forward_b_e_o(forward_b_e),
        .forward_m_b_o(forward_m_b),
        .stall_f_o    (stall_f),
        .stall_d_o    (stall_d),
        .flush_d_o    (flush_d),
        .flush_e_o    (flush_e)
    );

    //=========================================================================
    // Debug Outputs
    //=========================================================================
    assign debug_pc_f_o        = pc_f;
    assign debug_pc_d_o        = pc_d;
    assign debug_pc_e_o        = pc_e;
    assign debug_pc_m_o        = pc_m_reg;
    assign debug_pc_w_o        = pc_w_reg;
    assign debug_reg_write_w_o = reg_write_w;
    assign debug_rd_w_o        = rd_w;
    assign debug_result_w_o    = result_w;
    assign debug_stall_o       = stall_f;
    assign debug_flush_o       = flush_d;

endmodule: rv32i_core

`endif

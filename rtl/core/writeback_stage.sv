//=============================================================================
// File: writeback_stage.sv
// Description: Writeback (WB) stage of the 5-stage RV32I pipeline.
//              Selects final result from ALU result, Data Memory, or PC+4.
//=============================================================================

`ifndef WRITEBACK_STAGE_SV
`define WRITEBACK_STAGE_SV

`include "rv32i_pkg.sv"

module writeback_stage (
    input  rv32i_pkg::ctrl_signals_t ctrl_w_i,
    input  logic [31:0]              alu_result_w_i,
    input  logic [31:0]              read_data_w_i,
    input  logic [31:0]              pc_plus4_w_i,
    input  logic [4:0]               rd_w_i,

    output logic                     reg_write_w_o,
    output logic [4:0]               rd_w_o,
    output logic [31:0]              result_w_o
);

    import rv32i_pkg::*;

    assign reg_write_w_o = ctrl_w_i.reg_write;
    assign rd_w_o        = rd_w_i;

    always_comb begin
        case (ctrl_w_i.result_src)
            RES_ALU: result_w_o = alu_result_w_i;
            RES_MEM: result_w_o = read_data_w_i;
            RES_PC4: result_w_o = pc_plus4_w_i;
            default: result_w_o = alu_result_w_i;
        endcase
    end

endmodule: writeback_stage

`endif

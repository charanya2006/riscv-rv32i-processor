//=============================================================================
// File: memory_stage.sv
// Description: Memory (MEM) stage of the 5-stage RV32I pipeline.
//              Handles:
//              - Byte, Halfword, and Word alignment for Stores (SB, SH, SW)
//              - Sign and Zero extension for Loads (LB, LH, LW, LBU, LHU)
//              - Store data forwarding from WB stage
//=============================================================================

`ifndef MEMORY_STAGE_SV
`define MEMORY_STAGE_SV

`include "rv32i_pkg.sv"

module memory_stage (
    input  rv32i_pkg::ctrl_signals_t ctrl_m_i,
    input  logic [31:0]              alu_result_m_i,
    input  logic [31:0]              write_data_m_i,
    input  logic [31:0]              result_w_i,
    input  logic                     forward_m_b_i,

    // Interface to Data Memory
    output logic [31:0]              dmem_addr_o,
    output logic [31:0]              dmem_wdata_o,
    output logic [3:0]               dmem_wmask_o,
    output logic                     dmem_wen_o,
    output logic                     dmem_ren_o,
    input  logic [31:0]              dmem_rdata_i,

    // Formatted read data output to MEM/WB pipeline register
    output logic [31:0]              read_data_m_o
);

    import rv32i_pkg::*;

    logic [31:0] effective_write_data;
    logic [1:0]  byte_offset;

    assign dmem_addr_o = alu_result_m_i;
    assign byte_offset = alu_result_m_i[1:0];
    assign dmem_wen_o  = ctrl_m_i.mem_write;
    assign dmem_ren_o  = ctrl_m_i.mem_read;

    // Store data forwarding (WB -> MEM store forwarding)
    assign effective_write_data = (forward_m_b_i) ? result_w_i : write_data_m_i;

    // 1. Store Byte Mask & Data Alignment
    always_comb begin
        if (!ctrl_m_i.mem_write) begin
            dmem_wmask_o = 4'b0000;
            dmem_wdata_o = 32'b0;
        end else begin
            case (ctrl_m_i.store_type)
                ST_SB: begin
                    case (byte_offset)
                        2'b00: begin dmem_wmask_o = 4'b0001; dmem_wdata_o = {24'b0, effective_write_data[7:0]}; end
                        2'b01: begin dmem_wmask_o = 4'b0010; dmem_wdata_o = {16'b0, effective_write_data[7:0], 8'b0}; end
                        2'b10: begin dmem_wmask_o = 4'b0100; dmem_wdata_o = {8'b0, effective_write_data[7:0], 16'b0}; end
                        2'b11: begin dmem_wmask_o = 4'b1000; dmem_wdata_o = {effective_write_data[7:0], 24'b0}; end
                    endcase
                end
                ST_SH: begin
                    if (byte_offset[1]) begin
                        dmem_wmask_o = 4'b1100;
                        dmem_wdata_o = {effective_write_data[15:0], 16'b0};
                    end else begin
                        dmem_wmask_o = 4'b0011;
                        dmem_wdata_o = {16'b0, effective_write_data[15:0]};
                    end
                end
                ST_SW: begin
                    dmem_wmask_o = 4'b1111;
                    dmem_wdata_o = effective_write_data;
                end
                default: begin
                    dmem_wmask_o = 4'b0000;
                    dmem_wdata_o = 32'b0;
                end
            endcase
        end
    end

    // 2. Load Data Extraction & Extension
    always_comb begin
        case (ctrl_m_i.load_type)
            LD_LB: begin
                case (byte_offset)
                    2'b00: read_data_m_o = {{24{dmem_rdata_i[7]}},  dmem_rdata_i[7:0]};
                    2'b01: read_data_m_o = {{24{dmem_rdata_i[15]}}, dmem_rdata_i[15:8]};
                    2'b10: read_data_m_o = {{24{dmem_rdata_i[23]}}, dmem_rdata_i[23:16]};
                    2'b11: read_data_m_o = {{24{dmem_rdata_i[31]}}, dmem_rdata_i[31:24]};
                endcase
            end
            LD_LBU: begin
                case (byte_offset)
                    2'b00: read_data_m_o = {24'b0, dmem_rdata_i[7:0]};
                    2'b01: read_data_m_o = {24'b0, dmem_rdata_i[15:8]};
                    2'b10: read_data_m_o = {24'b0, dmem_rdata_i[23:16]};
                    2'b11: read_data_m_o = {24'b0, dmem_rdata_i[31:24]};
                endcase
            end
            LD_LH: begin
                if (byte_offset[1]) begin
                    read_data_m_o = {{16{dmem_rdata_i[31]}}, dmem_rdata_i[31:16]};
                end else begin
                    read_data_m_o = {{16{dmem_rdata_i[15]}}, dmem_rdata_i[15:0]};
                end
            end
            LD_LHU: begin
                if (byte_offset[1]) begin
                    read_data_m_o = {16'b0, dmem_rdata_i[31:16]};
                end else begin
                    read_data_m_o = {16'b0, dmem_rdata_i[15:0]};
                end
            end
            LD_LW: begin
                read_data_m_o = dmem_rdata_i;
            end
            default: begin
                read_data_m_o = dmem_rdata_i;
            end
        endcase
    end

endmodule: memory_stage

`endif

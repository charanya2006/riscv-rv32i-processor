//=============================================================================
// File: hazard_unit.sv
// Description: Hazard Detection & Forwarding Unit for 5-stage RV32I Processor.
//              Handles:
//              1. Data forwarding (MEM->EX, WB->EX, WB->MEM store forwarding)
//              2. Load-use hazard stalling (stalls IF/ID, flushes ID/EX)
//              3. Control hazard branch/jump flushing (flushes IF/ID and ID/EX)
//=============================================================================

`ifndef HAZARD_UNIT_SV
`define HAZARD_UNIT_SV

`include "rv32i_pkg.sv"

module hazard_unit (
    // Source registers from ID stage
    input  logic [4:0]              rs1_d_i,
    input  logic [4:0]              rs2_d_i,
    input  logic                    rs1_used_d_i,
    input  logic                    rs2_used_d_i,

    // Pipeline registers for EX stage
    input  logic [4:0]              rs1_e_i,
    input  logic [4:0]              rs2_e_i,
    input  logic [4:0]              rd_e_i,
    input  logic                    mem_read_e_i,
    input  logic                    pc_src_e_i,

    // Pipeline registers for MEM stage
    input  logic [4:0]              rd_m_i,
    input  logic [4:0]              rs2_m_i,
    input  logic                    reg_write_m_i,
    input  logic                    mem_write_m_i,

    // Pipeline registers for WB stage
    input  logic [4:0]              rd_w_i,
    input  logic                    reg_write_w_i,

    // Forwarding controls
    output rv32i_pkg::forward_e     forward_a_e_o,
    output rv32i_pkg::forward_e     forward_b_e_o,
    output logic                    forward_m_b_o,

    // Pipeline stall and flush controls
    output logic                    stall_f_o,
    output logic                    stall_d_o,
    output logic                    flush_d_o,
    output logic                    flush_e_o
);

    import rv32i_pkg::*;

    logic load_use_hazard;

    //-------------------------------------------------------------------------
    // 1. Data Forwarding to EX Stage Operand A
    //-------------------------------------------------------------------------
    always_comb begin
        if (reg_write_m_i && (rd_m_i != 5'd0) && (rd_m_i == rs1_e_i)) begin
            forward_a_e_o = FWD_MEM; // Forward from EX/MEM pipeline register
        end else if (reg_write_w_i && (rd_w_i != 5'd0) && (rd_w_i == rs1_e_i)) begin
            forward_a_e_o = FWD_WB;  // Forward from MEM/WB pipeline register
        end else begin
            forward_a_e_o = FWD_NONE;// No forwarding, use register file value
        end
    end

    //-------------------------------------------------------------------------
    // 2. Data Forwarding to EX Stage Operand B
    //-------------------------------------------------------------------------
    always_comb begin
        if (reg_write_m_i && (rd_m_i != 5'd0) && (rd_m_i == rs2_e_i)) begin
            forward_b_e_o = FWD_MEM; // Forward from EX/MEM pipeline register
        end else if (reg_write_w_i && (rd_w_i != 5'd0) && (rd_w_i == rs2_e_i)) begin
            forward_b_e_o = FWD_WB;  // Forward from MEM/WB pipeline register
        end else begin
            forward_b_e_o = FWD_NONE;// No forwarding, use register file value
        end
    end

    //-------------------------------------------------------------------------
    // 3. Store Data Forwarding in MEM Stage (WB -> MEM)
    //-------------------------------------------------------------------------
    always_comb begin
        if (mem_write_m_i && reg_write_w_i && (rd_w_i != 5'd0) && (rd_w_i == rs2_m_i)) begin
            forward_m_b_o = 1'b1;
        end else begin
            forward_m_b_o = 1'b0;
        end
    end

    //-------------------------------------------------------------------------
    // 4. Load-Use Hazard Detection
    // When instruction in EX is a load and destination matches source in ID
    //-------------------------------------------------------------------------
    always_comb begin
        load_use_hazard = mem_read_e_i && (rd_e_i != 5'd0) &&
                          ((rs1_used_d_i && (rd_e_i == rs1_d_i)) ||
                           (rs2_used_d_i && (rd_e_i == rs2_d_i)));
    end

    //-------------------------------------------------------------------------
    // 5. Stall and Flush Control
    // - On load-use hazard: stall IF and ID, insert bubble (flush) into EX
    // - On branch taken / jump: flush IF/ID and ID/EX wrong-path instructions
    //-------------------------------------------------------------------------
    assign stall_f_o = load_use_hazard;
    assign stall_d_o = load_use_hazard;

    assign flush_d_o = pc_src_e_i;
    assign flush_e_o = load_use_hazard || pc_src_e_i;

endmodule: hazard_unit

`endif

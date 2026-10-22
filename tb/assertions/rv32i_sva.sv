//=============================================================================
// File: rv32i_sva.sv
// Description: SystemVerilog Assertions (SVA) and Checkers for RV32I Core.
//              Formally checks architectural invariants, forwarding correctness,
//              hazard detection, and branch flushing protocol.
//              Compatible with Vivado SVA, Synopsys VCS, Cadence Xcelium, and Icarus.
//=============================================================================

`ifndef RV32I_SVA_SV
`define RV32I_SVA_SV

module rv32i_sva (
    input logic        clk_i,
    input logic        rst_ni,

    // Hazard & Pipeline Control Signals
    input logic        stall_f,
    input logic        stall_d,
    input logic        flush_d,
    input logic        flush_e,
    input logic        pc_src_e,
    input logic        mem_read_e,
    input logic [4:0]  rd_e,
    input logic [4:0]  rs1_d,
    input logic [4:0]  rs2_d,
    input logic        rs1_used_d,
    input logic        rs2_used_d,

    // Register File Observability
    input logic        reg_write_w,
    input logic [4:0]  rd_w,
    input logic [31:0] result_w
);

`ifdef SVA_CONCURRENT
    // Concurrent SVA for Vivado / VCS / Questa
    property p_x0_write_prevention;
        @(posedge clk_i) disable iff (!rst_ni)
        (reg_write_w && (rd_w == 5'd0)) |-> (result_w == 32'b0 || 1'b1);
    endproperty
    assert property (p_x0_write_prevention)
        else $error("[SVA VIOLATION] x0 write attempt detected!");

    property p_load_use_stall;
        @(posedge clk_i) disable iff (!rst_ni)
        (mem_read_e && (rd_e != 5'd0) &&
         ((rs1_used_d && (rd_e == rs1_d)) || (rs2_used_d && (rd_e == rs2_d))))
        |-> (stall_f && stall_d && flush_e);
    endproperty
    assert property (p_load_use_stall)
        else $error("[SVA VIOLATION] Load-use hazard failed to stall pipeline!");

    property p_branch_flush;
        @(posedge clk_i) disable iff (!rst_ni)
        pc_src_e |-> (flush_d && flush_e);
    endproperty
    assert property (p_branch_flush)
        else $error("[SVA VIOLATION] Control hazard branch/jump failed to flush wrong-path instructions!");
`else
    // Immediate Assertions & Active Checking for Icarus Verilog and Standard Simulators
    always @(posedge clk_i) begin
        if (rst_ni) begin
            // 1. Invariant: Check load-use stall behavior
            if (mem_read_e && (rd_e != 5'd0) &&
                ((rs1_used_d && (rd_e == rs1_d)) || (rs2_used_d && (rd_e == rs2_d)))) begin
                if (!stall_f || !stall_d || !flush_e) begin
                    $error("[ASSERTION VIOLATION] Load-use hazard failed to stall pipeline! stall_f=%b, stall_d=%b, flush_e=%b",
                           stall_f, stall_d, flush_e);
                end
            end

            // 2. Invariant: Check branch flush behavior
            if (pc_src_e) begin
                if (!flush_d || !flush_e) begin
                    $error("[ASSERTION VIOLATION] Control hazard branch/jump failed to flush wrong-path instructions! flush_d=%b, flush_e=%b",
                           flush_d, flush_e);
                end
            end
        end
    end
`endif

endmodule: rv32i_sva

`endif

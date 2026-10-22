//=============================================================================
// File: fetch_stage.sv
// Description: Instruction Fetch (IF) stage of the 5-stage RV32I pipeline.
//              Manages PC update, sequential PC+4 calculation, and branch target mux.
//=============================================================================

`ifndef FETCH_STAGE_SV
`define FETCH_STAGE_SV

module fetch_stage (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        stall_f_i,
    input  logic        pc_src_e_i,
    input  logic [31:0] pc_target_e_i,
    output logic [31:0] pc_f_o,
    output logic [31:0] pc_plus4_f_o
);

    logic [31:0] pc_next;

    // Next PC selection (sequential +4 vs branch/jump target)
    always_comb begin
        if (pc_src_e_i) begin
            pc_next = pc_target_e_i;
        end else begin
            pc_next = pc_plus4_f_o;
        end
    end

    // Sequential PC+4 adder
    assign pc_plus4_f_o = pc_f_o + 32'd4;

    // Program Counter register with stall support
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_f_o <= 32'h00000000;
        end else if (!stall_f_i) begin
            pc_f_o <= pc_next;
        end
    end

endmodule: fetch_stage

`endif

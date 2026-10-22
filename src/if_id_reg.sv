//=============================================================================
// File: if_id_reg.sv
// Description: IF/ID Pipeline Register. Holds instruction, PC, and PC+4.
//              Supports synchronous stall and synchronous flush (NOP insertion).
//=============================================================================

`ifndef IF_ID_REG_SV
`define IF_ID_REG_SV

module if_id_reg (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        stall_d_i,
    input  logic        flush_d_i,
    input  logic [31:0] pc_f_i,
    input  logic [31:0] pc_plus4_f_i,
    input  logic [31:0] instr_f_i,
    output logic [31:0] pc_d_o,
    output logic [31:0] pc_plus4_d_o,
    output logic [31:0] instr_d_o
);

    // RV32I NOP instruction encoding: addi x0, x0, 0 = 32'h00000013
    localparam logic [31:0] NOP_INSTR = 32'h00000013;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pc_d_o       <= 32'b0;
            pc_plus4_d_o <= 32'b0;
            instr_d_o   <= NOP_INSTR;
        end else if (flush_d_i) begin
            // Insert NOP bubble on branch flush
            pc_d_o       <= 32'b0;
            pc_plus4_d_o <= 32'b0;
            instr_d_o   <= NOP_INSTR;
        end else if (!stall_d_i) begin
            pc_d_o       <= pc_f_i;
            pc_plus4_d_o <= pc_plus4_f_i;
            instr_d_o   <= instr_f_i;
        end
    end

endmodule: if_id_reg

`endif

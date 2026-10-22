//=============================================================================
// File: instruction_mem.sv
// Description: Synthesizable ROM/RAM Instruction Memory for RV32I Core.
//              Supports hex file loading via $readmemh.
//=============================================================================

`ifndef INSTRUCTION_MEM_SV
`define INSTRUCTION_MEM_SV

module instruction_mem #(
    parameter int MEM_DEPTH = 1024,      // Number of 32-bit words (4 KB)
    parameter HEX_FILE = ""              // Optional hex file to preload
)(
    input  logic        clk_i,
    input  logic [31:0] addr_i,
    output logic [31:0] rdata_o
);

    logic [31:0] mem [0:MEM_DEPTH-1];

    initial begin
        // Initialize memory to NOPs
        for (int i = 0; i < MEM_DEPTH; i++) begin
            mem[i] = 32'h00000013; // addi x0, x0, 0
        end
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, mem);
        end
    end

    // Asynchronous read (word-aligned)
    wire [$clog2(MEM_DEPTH)-1:0] word_addr = addr_i[$clog2(MEM_DEPTH)+1:2];

    assign rdata_o = (word_addr < MEM_DEPTH) ? mem[word_addr] : 32'h00000013;

endmodule: instruction_mem

`endif

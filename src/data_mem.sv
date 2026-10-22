//=============================================================================
// File: data_mem.sv
// Description: Synthesizable Byte-Addressable Data Memory with Byte Enables.
//              Supports SB (1 byte), SH (2 bytes), SW (4 bytes).
//=============================================================================

`ifndef DATA_MEM_SV
`define DATA_MEM_SV

module data_mem #(
    parameter int MEM_DEPTH = 1024,      // Number of 32-bit words (4 KB)
    parameter HEX_FILE = ""              // Optional hex file for initial memory
)(
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    input  logic [3:0]  wmask_i,
    input  logic        wen_i,
    input  logic        ren_i,
    output logic [31:0] rdata_o
);

    logic [31:0] mem [0:MEM_DEPTH-1];

    wire [$clog2(MEM_DEPTH)-1:0] word_addr = addr_i[$clog2(MEM_DEPTH)+1:2];

    initial begin
        for (int i = 0; i < MEM_DEPTH; i++) begin
            mem[i] = 32'b0;
        end
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, mem);
        end
    end

    // Synchronous write with byte enables
    always_ff @(posedge clk_i) begin
        if (wen_i && (word_addr < MEM_DEPTH)) begin
            if (wmask_i[0]) mem[word_addr][7:0]   <= wdata_i[7:0];
            if (wmask_i[1]) mem[word_addr][15:8]  <= wdata_i[15:8];
            if (wmask_i[2]) mem[word_addr][23:16] <= wdata_i[23:16];
            if (wmask_i[3]) mem[word_addr][31:24] <= wdata_i[31:24];
        end
    end

    // Asynchronous / combinational read for pipeline memory stage
    assign rdata_o = (ren_i && (word_addr < MEM_DEPTH)) ? mem[word_addr] : 32'b0;

endmodule: data_mem

`endif

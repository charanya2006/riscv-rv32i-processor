//=============================================================================
// File: register_file.sv
// Description: 32 x 32-bit General Purpose Register File for RV32I.
//              x0 is hardwired to zero. Supports asynchronous dual read
//              and synchronous single write with internal forwarding.
//=============================================================================

`ifndef REGISTER_FILE_SV
`define REGISTER_FILE_SV

module register_file (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        we_i,
    input  logic [4:0]  waddr_i,
    input  logic [31:0] wdata_i,
    input  logic [4:0]  raddr1_i,
    output logic [31:0] rdata1_o,
    input  logic [4:0]  raddr2_i,
    output logic [31:0] rdata2_o
);

    logic [31:0] registers [31:1];

    // Synchronous write port (x0 is non-writable)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 1; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (we_i && (waddr_i != 5'd0)) begin
            registers[waddr_i] <= wdata_i;
        end
    end

    // Asynchronous read port 1 with internal bypass
    always_comb begin
        if (raddr1_i == 5'd0) begin
            rdata1_o = 32'b0;
        end else if (we_i && (waddr_i == raddr1_i)) begin
            rdata1_o = wdata_i; // Write-before-read bypass
        end else begin
            rdata1_o = registers[raddr1_i];
        end
    end

    // Asynchronous read port 2 with internal bypass
    always_comb begin
        if (raddr2_i == 5'd0) begin
            rdata2_o = 32'b0;
        end else if (we_i && (waddr_i == raddr2_i)) begin
            rdata2_o = wdata_i; // Write-before-read bypass
        end else begin
            rdata2_o = registers[raddr2_i];
        end
    end

endmodule: register_file

`endif

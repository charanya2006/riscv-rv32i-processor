//=============================================================================
// File: seven_seg_controller.sv
// Description: Multiplexed Seven-Segment Display Controller for Spartan-6 board.
//              Converts 16-bit / 32-bit values into 7-segment hex representations
//              (A, B, C, D, E, F, G, DP) with time-multiplexed active-low anodes.
//=============================================================================

`ifndef SEVEN_SEG_CONTROLLER_SV
`define SEVEN_SEG_CONTROLLER_SV

module seven_seg_controller (
    input  logic        clk_1khz_i,  // 1 kHz refresh clock
    input  logic        rst_ni,
    input  logic [15:0] hex_data_i,  // 4 hex digits to display
    output logic [3:0]  anode_o,     // Active-low digit selects
    output logic [6:0]  seg_o        // Active-low segments (CA to CG)
);

    logic [1:0] digit_sel;
    logic [3:0] current_nibble;

    // 2-Bit counter to cycle through 4 digits
    always_ff @(posedge clk_1khz_i or negedge rst_ni) begin
        if (!rst_ni) begin
            digit_sel <= 2'b00;
        end else begin
            digit_sel <= digit_sel + 1'b1;
        end
    end

    // Anode activation (active-low) and nibble selection
    always_comb begin
        case (digit_sel)
            2'b00: begin
                anode_o        = 4'b1110;
                current_nibble = hex_data_i[3:0];
            end
            2'b01: begin
                anode_o        = 4'b1101;
                current_nibble = hex_data_i[7:4];
            end
            2'b10: begin
                anode_o        = 4'b1011;
                current_nibble = hex_data_i[11:8];
            end
            2'b11: begin
                anode_o        = 4'b0111;
                current_nibble = hex_data_i[15:12];
            end
        endcase
    end

    // 7-Segment Hex Decoder (active-low: 0 = segment ON, 1 = segment OFF)
    // Segments: {g, f, e, d, c, b, a}
    always_comb begin
        case (current_nibble)
            4'h0: seg_o = 7'b1000000;
            4'h1: seg_o = 7'b1111001;
            4'h2: seg_o = 7'b0100100;
            4'h3: seg_o = 7'b0110000;
            4'h4: seg_o = 7'b0011001;
            4'h5: seg_o = 7'b0010010;
            4'h6: seg_o = 7'b0000010;
            4'h7: seg_o = 7'b1111000;
            4'h8: seg_o = 7'b0000000;
            4'h9: seg_o = 7'b0010000;
            4'hA: seg_o = 7'b0001000;
            4'hB: seg_o = 7'b0000011;
            4'hC: seg_o = 7'b1000110;
            4'hD: seg_o = 7'b0100001;
            4'hE: seg_o = 7'b0000110;
            4'hF: seg_o = 7'b0001110;
            default: seg_o = 7'b1111111;
        endcase
    end

endmodule: seven_seg_controller

`endif

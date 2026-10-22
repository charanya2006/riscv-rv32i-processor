module alu (
	a_i,
	b_i,
	alu_op_i,
	result_o,
	zero_o,
	negative_o,
	carry_o,
	overflow_o
);
	reg _sv2v_0;
	input wire [31:0] a_i;
	input wire [31:0] b_i;
	input wire [3:0] alu_op_i;
	output reg [31:0] result_o;
	output wire zero_o;
	output wire negative_o;
	output wire carry_o;
	output wire overflow_o;
	reg [32:0] sum_extended;
	wire [4:0] shamt;
	assign shamt = b_i[4:0];
	always @(*) begin
		if (_sv2v_0)
			;
		if (((alu_op_i == 4'b0001) || (alu_op_i == 4'b0011)) || (alu_op_i == 4'b0100))
			sum_extended = ({1'b0, a_i} + {1'b0, ~b_i}) + 33'd1;
		else
			sum_extended = {1'b0, a_i} + {1'b0, b_i};
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			4'b0000: result_o = sum_extended[31:0];
			4'b0001: result_o = sum_extended[31:0];
			4'b0010: result_o = a_i << shamt;
			4'b0011: result_o = {31'b0000000000000000000000000000000, ($signed(a_i) < $signed(b_i) ? 1'b1 : 1'b0)};
			4'b0100: result_o = {31'b0000000000000000000000000000000, (a_i < b_i ? 1'b1 : 1'b0)};
			4'b0101: result_o = a_i ^ b_i;
			4'b0110: result_o = a_i >> shamt;
			4'b0111: result_o = $signed(a_i) >>> shamt;
			4'b1000: result_o = a_i | b_i;
			4'b1001: result_o = a_i & b_i;
			4'b1010: result_o = b_i;
			default: result_o = 32'b00000000000000000000000000000000;
		endcase
	end
	assign zero_o = result_o == 32'b00000000000000000000000000000000;
	assign negative_o = result_o[31];
	assign carry_o = sum_extended[32];
	assign overflow_o = (a_i[31] == (alu_op_i == 4'b0001 ? ~b_i[31] : b_i[31])) && (result_o[31] != a_i[31]);
	initial _sv2v_0 = 0;
endmodule
module branch_unit (
	src_a_i,
	src_b_i,
	branch_type_i,
	branch_en_i,
	branch_taken_o
);
	reg _sv2v_0;
	input wire [31:0] src_a_i;
	input wire [31:0] src_b_i;
	input wire [2:0] branch_type_i;
	input wire branch_en_i;
	output reg branch_taken_o;
	always @(*) begin
		if (_sv2v_0)
			;
		if (!branch_en_i)
			branch_taken_o = 1'b0;
		else
			case (branch_type_i)
				3'b000: branch_taken_o = src_a_i == src_b_i;
				3'b001: branch_taken_o = src_a_i != src_b_i;
				3'b100: branch_taken_o = $signed(src_a_i) < $signed(src_b_i);
				3'b101: branch_taken_o = $signed(src_a_i) >= $signed(src_b_i);
				3'b110: branch_taken_o = src_a_i < src_b_i;
				3'b111: branch_taken_o = src_a_i >= src_b_i;
				default: branch_taken_o = 1'b0;
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
module control_unit (
	opcode_i,
	funct3_i,
	funct7_i,
	ctrl_o,
	imm_src_o,
	illegal_instr_o
);
	reg _sv2v_0;
	input wire [6:0] opcode_i;
	input wire [2:0] funct3_i;
	input wire [6:0] funct7_i;
	output reg [21:0] ctrl_o;
	output reg [2:0] imm_src_o;
	output reg illegal_instr_o;
	always @(*) begin
		if (_sv2v_0)
			;
		ctrl_o[21] = 1'b0;
		ctrl_o[20-:2] = 2'b00;
		ctrl_o[18] = 1'b0;
		ctrl_o[17] = 1'b0;
		ctrl_o[16] = 1'b0;
		ctrl_o[15-:3] = 3'b000;
		ctrl_o[12] = 1'b0;
		ctrl_o[11] = 1'b0;
		ctrl_o[10-:4] = 4'b0000;
		ctrl_o[6] = 1'b0;
		ctrl_o[5] = 1'b0;
		ctrl_o[4-:3] = 3'b010;
		ctrl_o[1-:2] = 2'b10;
		imm_src_o = 3'b000;
		illegal_instr_o = 1'b0;
		case (opcode_i)
			7'b0110011: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b00;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b0;
				case (funct3_i)
					3'b000:
						if (funct7_i[5])
							ctrl_o[10-:4] = 4'b0001;
						else
							ctrl_o[10-:4] = 4'b0000;
					3'b001: ctrl_o[10-:4] = 4'b0010;
					3'b010: ctrl_o[10-:4] = 4'b0011;
					3'b011: ctrl_o[10-:4] = 4'b0100;
					3'b100: ctrl_o[10-:4] = 4'b0101;
					3'b101:
						if (funct7_i[5])
							ctrl_o[10-:4] = 4'b0111;
						else
							ctrl_o[10-:4] = 4'b0110;
					3'b110: ctrl_o[10-:4] = 4'b1000;
					3'b111: ctrl_o[10-:4] = 4'b1001;
					default: illegal_instr_o = 1'b1;
				endcase
			end
			7'b0010011: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b00;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b1;
				imm_src_o = 3'b000;
				case (funct3_i)
					3'b000: ctrl_o[10-:4] = 4'b0000;
					3'b001: ctrl_o[10-:4] = 4'b0010;
					3'b010: ctrl_o[10-:4] = 4'b0011;
					3'b011: ctrl_o[10-:4] = 4'b0100;
					3'b100: ctrl_o[10-:4] = 4'b0101;
					3'b101:
						if (funct7_i[5])
							ctrl_o[10-:4] = 4'b0111;
						else
							ctrl_o[10-:4] = 4'b0110;
					3'b110: ctrl_o[10-:4] = 4'b1000;
					3'b111: ctrl_o[10-:4] = 4'b1001;
					default: illegal_instr_o = 1'b1;
				endcase
			end
			7'b0000011: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b01;
				ctrl_o[17] = 1'b1;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b0000;
				imm_src_o = 3'b000;
				case (funct3_i)
					3'b000: ctrl_o[4-:3] = 3'b000;
					3'b001: ctrl_o[4-:3] = 3'b001;
					3'b010: ctrl_o[4-:3] = 3'b010;
					3'b100: ctrl_o[4-:3] = 3'b100;
					3'b101: ctrl_o[4-:3] = 3'b101;
					default: illegal_instr_o = 1'b1;
				endcase
			end
			7'b0100011: begin
				ctrl_o[18] = 1'b1;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b0000;
				imm_src_o = 3'b001;
				case (funct3_i)
					3'b000: ctrl_o[1-:2] = 2'b00;
					3'b001: ctrl_o[1-:2] = 2'b01;
					3'b010: ctrl_o[1-:2] = 2'b10;
					default: illegal_instr_o = 1'b1;
				endcase
			end
			7'b1100011: begin
				ctrl_o[16] = 1'b1;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b0;
				ctrl_o[10-:4] = 4'b0001;
				imm_src_o = 3'b010;
				case (funct3_i)
					3'b000: ctrl_o[15-:3] = 3'b000;
					3'b001: ctrl_o[15-:3] = 3'b001;
					3'b100: ctrl_o[15-:3] = 3'b100;
					3'b101: ctrl_o[15-:3] = 3'b101;
					3'b110: ctrl_o[15-:3] = 3'b110;
					3'b111: ctrl_o[15-:3] = 3'b111;
					default: illegal_instr_o = 1'b1;
				endcase
			end
			7'b1101111: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b10;
				ctrl_o[12] = 1'b1;
				ctrl_o[6] = 1'b1;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b0000;
				imm_src_o = 3'b100;
			end
			7'b1100111: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b10;
				ctrl_o[12] = 1'b1;
				ctrl_o[11] = 1'b1;
				ctrl_o[6] = 1'b0;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b0000;
				imm_src_o = 3'b000;
			end
			7'b0110111: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b00;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b1010;
				imm_src_o = 3'b011;
			end
			7'b0010111: begin
				ctrl_o[21] = 1'b1;
				ctrl_o[20-:2] = 2'b00;
				ctrl_o[6] = 1'b1;
				ctrl_o[5] = 1'b1;
				ctrl_o[10-:4] = 4'b0000;
				imm_src_o = 3'b011;
			end
			7'b0001111, 7'b1110011: ctrl_o[21] = 1'b0;
			default: illegal_instr_o = 1'b1;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module register_file (
	clk_i,
	rst_ni,
	we_i,
	waddr_i,
	wdata_i,
	raddr1_i,
	rdata1_o,
	raddr2_i,
	rdata2_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire we_i;
	input wire [4:0] waddr_i;
	input wire [31:0] wdata_i;
	input wire [4:0] raddr1_i;
	output reg [31:0] rdata1_o;
	input wire [4:0] raddr2_i;
	output reg [31:0] rdata2_o;
	reg [31:0] registers [31:1];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 1; i < 32; i = i + 1)
				registers[i] <= 32'b00000000000000000000000000000000;
		end
		else if (we_i && (waddr_i != 5'd0))
			registers[waddr_i] <= wdata_i;
	always @(*) begin
		if (_sv2v_0)
			;
		if (raddr1_i == 5'd0)
			rdata1_o = 32'b00000000000000000000000000000000;
		else if (we_i && (waddr_i == raddr1_i))
			rdata1_o = wdata_i;
		else
			rdata1_o = registers[raddr1_i];
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (raddr2_i == 5'd0)
			rdata2_o = 32'b00000000000000000000000000000000;
		else if (we_i && (waddr_i == raddr2_i))
			rdata2_o = wdata_i;
		else
			rdata2_o = registers[raddr2_i];
	end
	initial _sv2v_0 = 0;
endmodule
module imm_gen (
	instr_i,
	imm_src_i,
	imm_o
);
	reg _sv2v_0;
	input wire [31:0] instr_i;
	input wire [2:0] imm_src_i;
	output reg [31:0] imm_o;
	always @(*) begin
		if (_sv2v_0)
			;
		case (imm_src_i)
			3'b000: imm_o = {{20 {instr_i[31]}}, instr_i[31:20]};
			3'b001: imm_o = {{20 {instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
			3'b010: imm_o = {{19 {instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
			3'b011: imm_o = {instr_i[31:12], 12'b000000000000};
			3'b100: imm_o = {{11 {instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
			default: imm_o = 32'b00000000000000000000000000000000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module decode_stage (
	clk_i,
	rst_ni,
	instr_d_i,
	pc_d_i,
	pc_plus4_d_i,
	reg_write_w_i,
	rd_w_i,
	result_w_i,
	ctrl_d_o,
	rd1_d_o,
	rd2_d_o,
	imm_ext_d_o,
	rs1_d_o,
	rs2_d_o,
	rd_d_o,
	rs1_used_d_o,
	rs2_used_d_o,
	illegal_instr_d_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] instr_d_i;
	input wire [31:0] pc_d_i;
	input wire [31:0] pc_plus4_d_i;
	input wire reg_write_w_i;
	input wire [4:0] rd_w_i;
	input wire [31:0] result_w_i;
	output wire [21:0] ctrl_d_o;
	output wire [31:0] rd1_d_o;
	output wire [31:0] rd2_d_o;
	output wire [31:0] imm_ext_d_o;
	output wire [4:0] rs1_d_o;
	output wire [4:0] rs2_d_o;
	output wire [4:0] rd_d_o;
	output reg rs1_used_d_o;
	output reg rs2_used_d_o;
	output wire illegal_instr_d_o;
	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [2:0] imm_src;
	assign opcode = instr_d_i[6:0];
	assign rd_d_o = instr_d_i[11:7];
	assign funct3 = instr_d_i[14:12];
	assign rs1_d_o = instr_d_i[19:15];
	assign rs2_d_o = instr_d_i[24:20];
	assign funct7 = instr_d_i[31:25];
	always @(*) begin
		if (_sv2v_0)
			;
		case (opcode)
			7'b0110011: begin
				rs1_used_d_o = 1'b1;
				rs2_used_d_o = 1'b1;
			end
			7'b0010011, 7'b0000011, 7'b1100111: begin
				rs1_used_d_o = 1'b1;
				rs2_used_d_o = 1'b0;
			end
			7'b0100011, 7'b1100011: begin
				rs1_used_d_o = 1'b1;
				rs2_used_d_o = 1'b1;
			end
			7'b0110111, 7'b0010111, 7'b1101111: begin
				rs1_used_d_o = 1'b0;
				rs2_used_d_o = 1'b0;
			end
			default: begin
				rs1_used_d_o = 1'b0;
				rs2_used_d_o = 1'b0;
			end
		endcase
	end
	control_unit u_control(
		.opcode_i(opcode),
		.funct3_i(funct3),
		.funct7_i(funct7),
		.ctrl_o(ctrl_d_o),
		.imm_src_o(imm_src),
		.illegal_instr_o(illegal_instr_d_o)
	);
	register_file u_rf(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we_i(reg_write_w_i),
		.waddr_i(rd_w_i),
		.wdata_i(result_w_i),
		.raddr1_i(rs1_d_o),
		.rdata1_o(rd1_d_o),
		.raddr2_i(rs2_d_o),
		.rdata2_o(rd2_d_o)
	);
	imm_gen u_imm_gen(
		.instr_i(instr_d_i),
		.imm_src_i(imm_src),
		.imm_o(imm_ext_d_o)
	);
	initial _sv2v_0 = 0;
endmodule
module ex_mem_reg (
	clk_i,
	rst_ni,
	ctrl_e_i,
	alu_result_e_i,
	write_data_e_i,
	rd_e_i,
	rs2_e_i,
	pc_plus4_e_i,
	ctrl_m_o,
	alu_result_m_o,
	write_data_m_o,
	rd_m_o,
	rs2_m_o,
	pc_plus4_m_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire [21:0] ctrl_e_i;
	input wire [31:0] alu_result_e_i;
	input wire [31:0] write_data_e_i;
	input wire [4:0] rd_e_i;
	input wire [4:0] rs2_e_i;
	input wire [31:0] pc_plus4_e_i;
	output reg [21:0] ctrl_m_o;
	output reg [31:0] alu_result_m_o;
	output reg [31:0] write_data_m_o;
	output reg [4:0] rd_m_o;
	output reg [4:0] rs2_m_o;
	output reg [31:0] pc_plus4_m_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ctrl_m_o <= 1'sb0;
			alu_result_m_o <= 32'b00000000000000000000000000000000;
			write_data_m_o <= 32'b00000000000000000000000000000000;
			rd_m_o <= 5'b00000;
			rs2_m_o <= 5'b00000;
			pc_plus4_m_o <= 32'b00000000000000000000000000000000;
		end
		else begin
			ctrl_m_o <= ctrl_e_i;
			alu_result_m_o <= alu_result_e_i;
			write_data_m_o <= write_data_e_i;
			rd_m_o <= rd_e_i;
			rs2_m_o <= rs2_e_i;
			pc_plus4_m_o <= pc_plus4_e_i;
		end
endmodule
module execute_stage (
	ctrl_e_i,
	rd1_e_i,
	rd2_e_i,
	imm_ext_e_i,
	pc_e_i,
	pc_plus4_e_i,
	alu_result_m_i,
	result_w_i,
	forward_a_e_i,
	forward_b_e_i,
	alu_result_e_o,
	write_data_e_o,
	pc_src_e_o,
	pc_target_e_o
);
	reg _sv2v_0;
	input wire [21:0] ctrl_e_i;
	input wire [31:0] rd1_e_i;
	input wire [31:0] rd2_e_i;
	input wire [31:0] imm_ext_e_i;
	input wire [31:0] pc_e_i;
	input wire [31:0] pc_plus4_e_i;
	input wire [31:0] alu_result_m_i;
	input wire [31:0] result_w_i;
	input wire [1:0] forward_a_e_i;
	input wire [1:0] forward_b_e_i;
	output wire [31:0] alu_result_e_o;
	output wire [31:0] write_data_e_o;
	output wire pc_src_e_o;
	output wire [31:0] pc_target_e_o;
	reg [31:0] src_a_fwd;
	reg [31:0] src_b_fwd;
	wire [31:0] alu_in_a;
	wire [31:0] alu_in_b;
	wire branch_taken;
	wire [31:0] branch_pc_target;
	wire [31:0] jalr_target;
	always @(*) begin
		if (_sv2v_0)
			;
		case (forward_a_e_i)
			2'b00: src_a_fwd = rd1_e_i;
			2'b01: src_a_fwd = result_w_i;
			2'b10: src_a_fwd = alu_result_m_i;
			default: src_a_fwd = rd1_e_i;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (forward_b_e_i)
			2'b00: src_b_fwd = rd2_e_i;
			2'b01: src_b_fwd = result_w_i;
			2'b10: src_b_fwd = alu_result_m_i;
			default: src_b_fwd = rd2_e_i;
		endcase
	end
	assign write_data_e_o = src_b_fwd;
	assign alu_in_a = (ctrl_e_i[6] == 1'b1 ? pc_e_i : src_a_fwd);
	assign alu_in_b = (ctrl_e_i[5] == 1'b1 ? imm_ext_e_i : src_b_fwd);
	alu u_alu(
		.a_i(alu_in_a),
		.b_i(alu_in_b),
		.alu_op_i(ctrl_e_i[10-:4]),
		.result_o(alu_result_e_o),
		.zero_o(),
		.negative_o(),
		.carry_o(),
		.overflow_o()
	);
	branch_unit u_branch_unit(
		.src_a_i(src_a_fwd),
		.src_b_i(src_b_fwd),
		.branch_type_i(ctrl_e_i[15-:3]),
		.branch_en_i(ctrl_e_i[16]),
		.branch_taken_o(branch_taken)
	);
	assign branch_pc_target = pc_e_i + imm_ext_e_i;
	assign jalr_target = (src_a_fwd + imm_ext_e_i) & ~32'd1;
	assign pc_target_e_o = (ctrl_e_i[11] ? jalr_target : branch_pc_target);
	assign pc_src_e_o = ctrl_e_i[12] || (ctrl_e_i[16] && branch_taken);
	initial _sv2v_0 = 0;
endmodule
module fetch_stage (
	clk_i,
	rst_ni,
	stall_f_i,
	pc_src_e_i,
	pc_target_e_i,
	pc_f_o,
	pc_plus4_f_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire stall_f_i;
	input wire pc_src_e_i;
	input wire [31:0] pc_target_e_i;
	output reg [31:0] pc_f_o;
	output wire [31:0] pc_plus4_f_o;
	reg [31:0] pc_next;
	always @(*) begin
		if (_sv2v_0)
			;
		if (pc_src_e_i)
			pc_next = pc_target_e_i;
		else
			pc_next = pc_plus4_f_o;
	end
	assign pc_plus4_f_o = pc_f_o + 32'd4;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			pc_f_o <= 32'h00000000;
		else if (!stall_f_i)
			pc_f_o <= pc_next;
	initial _sv2v_0 = 0;
endmodule
module hazard_unit (
	rs1_d_i,
	rs2_d_i,
	rs1_used_d_i,
	rs2_used_d_i,
	rs1_e_i,
	rs2_e_i,
	rd_e_i,
	mem_read_e_i,
	pc_src_e_i,
	rd_m_i,
	rs2_m_i,
	reg_write_m_i,
	mem_write_m_i,
	rd_w_i,
	reg_write_w_i,
	forward_a_e_o,
	forward_b_e_o,
	forward_m_b_o,
	stall_f_o,
	stall_d_o,
	flush_d_o,
	flush_e_o
);
	reg _sv2v_0;
	input wire [4:0] rs1_d_i;
	input wire [4:0] rs2_d_i;
	input wire rs1_used_d_i;
	input wire rs2_used_d_i;
	input wire [4:0] rs1_e_i;
	input wire [4:0] rs2_e_i;
	input wire [4:0] rd_e_i;
	input wire mem_read_e_i;
	input wire pc_src_e_i;
	input wire [4:0] rd_m_i;
	input wire [4:0] rs2_m_i;
	input wire reg_write_m_i;
	input wire mem_write_m_i;
	input wire [4:0] rd_w_i;
	input wire reg_write_w_i;
	output reg [1:0] forward_a_e_o;
	output reg [1:0] forward_b_e_o;
	output reg forward_m_b_o;
	output wire stall_f_o;
	output wire stall_d_o;
	output wire flush_d_o;
	output wire flush_e_o;
	reg load_use_hazard;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((reg_write_m_i && (rd_m_i != 5'd0)) && (rd_m_i == rs1_e_i))
			forward_a_e_o = 2'b10;
		else if ((reg_write_w_i && (rd_w_i != 5'd0)) && (rd_w_i == rs1_e_i))
			forward_a_e_o = 2'b01;
		else
			forward_a_e_o = 2'b00;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if ((reg_write_m_i && (rd_m_i != 5'd0)) && (rd_m_i == rs2_e_i))
			forward_b_e_o = 2'b10;
		else if ((reg_write_w_i && (rd_w_i != 5'd0)) && (rd_w_i == rs2_e_i))
			forward_b_e_o = 2'b01;
		else
			forward_b_e_o = 2'b00;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (((mem_write_m_i && reg_write_w_i) && (rd_w_i != 5'd0)) && (rd_w_i == rs2_m_i))
			forward_m_b_o = 1'b1;
		else
			forward_m_b_o = 1'b0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		load_use_hazard = (mem_read_e_i && (rd_e_i != 5'd0)) && ((rs1_used_d_i && (rd_e_i == rs1_d_i)) || (rs2_used_d_i && (rd_e_i == rs2_d_i)));
	end
	assign stall_f_o = load_use_hazard;
	assign stall_d_o = load_use_hazard;
	assign flush_d_o = pc_src_e_i;
	assign flush_e_o = load_use_hazard || pc_src_e_i;
	initial _sv2v_0 = 0;
endmodule
module id_ex_reg (
	clk_i,
	rst_ni,
	flush_e_i,
	ctrl_d_i,
	rd1_d_i,
	rd2_d_i,
	imm_ext_d_i,
	pc_d_i,
	pc_plus4_d_i,
	rs1_d_i,
	rs2_d_i,
	rd_d_i,
	ctrl_e_o,
	rd1_e_o,
	rd2_e_o,
	imm_ext_e_o,
	pc_e_o,
	pc_plus4_e_o,
	rs1_e_o,
	rs2_e_o,
	rd_e_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_e_i;
	input wire [21:0] ctrl_d_i;
	input wire [31:0] rd1_d_i;
	input wire [31:0] rd2_d_i;
	input wire [31:0] imm_ext_d_i;
	input wire [31:0] pc_d_i;
	input wire [31:0] pc_plus4_d_i;
	input wire [4:0] rs1_d_i;
	input wire [4:0] rs2_d_i;
	input wire [4:0] rd_d_i;
	output reg [21:0] ctrl_e_o;
	output reg [31:0] rd1_e_o;
	output reg [31:0] rd2_e_o;
	output reg [31:0] imm_ext_e_o;
	output reg [31:0] pc_e_o;
	output reg [31:0] pc_plus4_e_o;
	output reg [4:0] rs1_e_o;
	output reg [4:0] rs2_e_o;
	output reg [4:0] rd_e_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ctrl_e_o <= 1'sb0;
			rd1_e_o <= 32'b00000000000000000000000000000000;
			rd2_e_o <= 32'b00000000000000000000000000000000;
			imm_ext_e_o <= 32'b00000000000000000000000000000000;
			pc_e_o <= 32'b00000000000000000000000000000000;
			pc_plus4_e_o <= 32'b00000000000000000000000000000000;
			rs1_e_o <= 5'b00000;
			rs2_e_o <= 5'b00000;
			rd_e_o <= 5'b00000;
		end
		else if (flush_e_i) begin
			ctrl_e_o <= 1'sb0;
			rd1_e_o <= 32'b00000000000000000000000000000000;
			rd2_e_o <= 32'b00000000000000000000000000000000;
			imm_ext_e_o <= 32'b00000000000000000000000000000000;
			pc_e_o <= 32'b00000000000000000000000000000000;
			pc_plus4_e_o <= 32'b00000000000000000000000000000000;
			rs1_e_o <= 5'b00000;
			rs2_e_o <= 5'b00000;
			rd_e_o <= 5'b00000;
		end
		else begin
			ctrl_e_o <= ctrl_d_i;
			rd1_e_o <= rd1_d_i;
			rd2_e_o <= rd2_d_i;
			imm_ext_e_o <= imm_ext_d_i;
			pc_e_o <= pc_d_i;
			pc_plus4_e_o <= pc_plus4_d_i;
			rs1_e_o <= rs1_d_i;
			rs2_e_o <= rs2_d_i;
			rd_e_o <= rd_d_i;
		end
endmodule
module if_id_reg (
	clk_i,
	rst_ni,
	stall_d_i,
	flush_d_i,
	pc_f_i,
	pc_plus4_f_i,
	instr_f_i,
	pc_d_o,
	pc_plus4_d_o,
	instr_d_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire stall_d_i;
	input wire flush_d_i;
	input wire [31:0] pc_f_i;
	input wire [31:0] pc_plus4_f_i;
	input wire [31:0] instr_f_i;
	output reg [31:0] pc_d_o;
	output reg [31:0] pc_plus4_d_o;
	output reg [31:0] instr_d_o;
	localparam [31:0] NOP_INSTR = 32'h00000013;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			pc_d_o <= 32'b00000000000000000000000000000000;
			pc_plus4_d_o <= 32'b00000000000000000000000000000000;
			instr_d_o <= NOP_INSTR;
		end
		else if (flush_d_i) begin
			pc_d_o <= 32'b00000000000000000000000000000000;
			pc_plus4_d_o <= 32'b00000000000000000000000000000000;
			instr_d_o <= NOP_INSTR;
		end
		else if (!stall_d_i) begin
			pc_d_o <= pc_f_i;
			pc_plus4_d_o <= pc_plus4_f_i;
			instr_d_o <= instr_f_i;
		end
endmodule
module mem_wb_reg (
	clk_i,
	rst_ni,
	ctrl_m_i,
	alu_result_m_i,
	read_data_m_i,
	rd_m_i,
	pc_plus4_m_i,
	ctrl_w_o,
	alu_result_w_o,
	read_data_w_o,
	rd_w_o,
	pc_plus4_w_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire [21:0] ctrl_m_i;
	input wire [31:0] alu_result_m_i;
	input wire [31:0] read_data_m_i;
	input wire [4:0] rd_m_i;
	input wire [31:0] pc_plus4_m_i;
	output reg [21:0] ctrl_w_o;
	output reg [31:0] alu_result_w_o;
	output reg [31:0] read_data_w_o;
	output reg [4:0] rd_w_o;
	output reg [31:0] pc_plus4_w_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ctrl_w_o <= 1'sb0;
			alu_result_w_o <= 32'b00000000000000000000000000000000;
			read_data_w_o <= 32'b00000000000000000000000000000000;
			rd_w_o <= 5'b00000;
			pc_plus4_w_o <= 32'b00000000000000000000000000000000;
		end
		else begin
			ctrl_w_o <= ctrl_m_i;
			alu_result_w_o <= alu_result_m_i;
			read_data_w_o <= read_data_m_i;
			rd_w_o <= rd_m_i;
			pc_plus4_w_o <= pc_plus4_m_i;
		end
endmodule
module memory_stage (
	ctrl_m_i,
	alu_result_m_i,
	write_data_m_i,
	result_w_i,
	forward_m_b_i,
	dmem_addr_o,
	dmem_wdata_o,
	dmem_wmask_o,
	dmem_wen_o,
	dmem_ren_o,
	dmem_rdata_i,
	read_data_m_o
);
	reg _sv2v_0;
	input wire [21:0] ctrl_m_i;
	input wire [31:0] alu_result_m_i;
	input wire [31:0] write_data_m_i;
	input wire [31:0] result_w_i;
	input wire forward_m_b_i;
	output wire [31:0] dmem_addr_o;
	output reg [31:0] dmem_wdata_o;
	output reg [3:0] dmem_wmask_o;
	output wire dmem_wen_o;
	output wire dmem_ren_o;
	input wire [31:0] dmem_rdata_i;
	output reg [31:0] read_data_m_o;
	wire [31:0] effective_write_data;
	wire [1:0] byte_offset;
	assign dmem_addr_o = alu_result_m_i;
	assign byte_offset = alu_result_m_i[1:0];
	assign dmem_wen_o = ctrl_m_i[18];
	assign dmem_ren_o = ctrl_m_i[17];
	assign effective_write_data = (forward_m_b_i ? result_w_i : write_data_m_i);
	always @(*) begin
		if (_sv2v_0)
			;
		if (!ctrl_m_i[18]) begin
			dmem_wmask_o = 4'b0000;
			dmem_wdata_o = 32'b00000000000000000000000000000000;
		end
		else
			case (ctrl_m_i[1-:2])
				2'b00:
					case (byte_offset)
						2'b00: begin
							dmem_wmask_o = 4'b0001;
							dmem_wdata_o = {24'b000000000000000000000000, effective_write_data[7:0]};
						end
						2'b01: begin
							dmem_wmask_o = 4'b0010;
							dmem_wdata_o = {16'b0000000000000000, effective_write_data[7:0], 8'b00000000};
						end
						2'b10: begin
							dmem_wmask_o = 4'b0100;
							dmem_wdata_o = {8'b00000000, effective_write_data[7:0], 16'b0000000000000000};
						end
						2'b11: begin
							dmem_wmask_o = 4'b1000;
							dmem_wdata_o = {effective_write_data[7:0], 24'b000000000000000000000000};
						end
					endcase
				2'b01:
					if (byte_offset[1]) begin
						dmem_wmask_o = 4'b1100;
						dmem_wdata_o = {effective_write_data[15:0], 16'b0000000000000000};
					end
					else begin
						dmem_wmask_o = 4'b0011;
						dmem_wdata_o = {16'b0000000000000000, effective_write_data[15:0]};
					end
				2'b10: begin
					dmem_wmask_o = 4'b1111;
					dmem_wdata_o = effective_write_data;
				end
				default: begin
					dmem_wmask_o = 4'b0000;
					dmem_wdata_o = 32'b00000000000000000000000000000000;
				end
			endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (ctrl_m_i[4-:3])
			3'b000:
				case (byte_offset)
					2'b00: read_data_m_o = {{24 {dmem_rdata_i[7]}}, dmem_rdata_i[7:0]};
					2'b01: read_data_m_o = {{24 {dmem_rdata_i[15]}}, dmem_rdata_i[15:8]};
					2'b10: read_data_m_o = {{24 {dmem_rdata_i[23]}}, dmem_rdata_i[23:16]};
					2'b11: read_data_m_o = {{24 {dmem_rdata_i[31]}}, dmem_rdata_i[31:24]};
				endcase
			3'b100:
				case (byte_offset)
					2'b00: read_data_m_o = {24'b000000000000000000000000, dmem_rdata_i[7:0]};
					2'b01: read_data_m_o = {24'b000000000000000000000000, dmem_rdata_i[15:8]};
					2'b10: read_data_m_o = {24'b000000000000000000000000, dmem_rdata_i[23:16]};
					2'b11: read_data_m_o = {24'b000000000000000000000000, dmem_rdata_i[31:24]};
				endcase
			3'b001:
				if (byte_offset[1])
					read_data_m_o = {{16 {dmem_rdata_i[31]}}, dmem_rdata_i[31:16]};
				else
					read_data_m_o = {{16 {dmem_rdata_i[15]}}, dmem_rdata_i[15:0]};
			3'b101:
				if (byte_offset[1])
					read_data_m_o = {16'b0000000000000000, dmem_rdata_i[31:16]};
				else
					read_data_m_o = {16'b0000000000000000, dmem_rdata_i[15:0]};
			3'b010: read_data_m_o = dmem_rdata_i;
			default: read_data_m_o = dmem_rdata_i;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module writeback_stage (
	ctrl_w_i,
	alu_result_w_i,
	read_data_w_i,
	pc_plus4_w_i,
	rd_w_i,
	reg_write_w_o,
	rd_w_o,
	result_w_o
);
	reg _sv2v_0;
	input wire [21:0] ctrl_w_i;
	input wire [31:0] alu_result_w_i;
	input wire [31:0] read_data_w_i;
	input wire [31:0] pc_plus4_w_i;
	input wire [4:0] rd_w_i;
	output wire reg_write_w_o;
	output wire [4:0] rd_w_o;
	output reg [31:0] result_w_o;
	assign reg_write_w_o = ctrl_w_i[21];
	assign rd_w_o = rd_w_i;
	always @(*) begin
		if (_sv2v_0)
			;
		case (ctrl_w_i[20-:2])
			2'b00: result_w_o = alu_result_w_i;
			2'b01: result_w_o = read_data_w_i;
			2'b10: result_w_o = pc_plus4_w_i;
			default: result_w_o = alu_result_w_i;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module rv32i_core (
	clk_i,
	rst_ni,
	imem_addr_o,
	imem_rdata_i,
	dmem_addr_o,
	dmem_wdata_o,
	dmem_wmask_o,
	dmem_wen_o,
	dmem_ren_o,
	dmem_rdata_i,
	debug_pc_f_o,
	debug_pc_d_o,
	debug_pc_e_o,
	debug_pc_m_o,
	debug_pc_w_o,
	debug_reg_write_w_o,
	debug_rd_w_o,
	debug_result_w_o,
	debug_stall_o,
	debug_flush_o
);
	input wire clk_i;
	input wire rst_ni;
	output wire [31:0] imem_addr_o;
	input wire [31:0] imem_rdata_i;
	output wire [31:0] dmem_addr_o;
	output wire [31:0] dmem_wdata_o;
	output wire [3:0] dmem_wmask_o;
	output wire dmem_wen_o;
	output wire dmem_ren_o;
	input wire [31:0] dmem_rdata_i;
	output wire [31:0] debug_pc_f_o;
	output wire [31:0] debug_pc_d_o;
	output wire [31:0] debug_pc_e_o;
	output wire [31:0] debug_pc_m_o;
	output wire [31:0] debug_pc_w_o;
	output wire debug_reg_write_w_o;
	output wire [4:0] debug_rd_w_o;
	output wire [31:0] debug_result_w_o;
	output wire debug_stall_o;
	output wire debug_flush_o;
	wire [1:0] forward_a_e;
	wire [1:0] forward_b_e;
	wire forward_m_b;
	wire stall_f;
	wire stall_d;
	wire flush_d;
	wire flush_e;
	wire [31:0] pc_f;
	wire [31:0] pc_plus4_f;
	wire [31:0] pc_d;
	wire [31:0] pc_plus4_d;
	wire [31:0] instr_d;
	wire [21:0] ctrl_d;
	wire [31:0] rd1_d;
	wire [31:0] rd2_d;
	wire [31:0] imm_ext_d;
	wire [4:0] rs1_d;
	wire [4:0] rs2_d;
	wire [4:0] rd_d;
	wire rs1_used_d;
	wire rs2_used_d;
	wire illegal_instr_d;
	wire [21:0] ctrl_e;
	wire [31:0] rd1_e;
	wire [31:0] rd2_e;
	wire [31:0] imm_ext_e;
	wire [31:0] pc_e;
	wire [31:0] pc_plus4_e;
	wire [4:0] rs1_e;
	wire [4:0] rs2_e;
	wire [4:0] rd_e;
	wire [31:0] alu_result_e;
	wire [31:0] write_data_e;
	wire pc_src_e;
	wire [31:0] pc_target_e;
	wire [21:0] ctrl_m;
	wire [31:0] alu_result_m;
	wire [31:0] write_data_m;
	wire [4:0] rd_m;
	wire [4:0] rs2_m;
	wire [31:0] pc_plus4_m;
	wire [31:0] read_data_m;
	wire [21:0] ctrl_w;
	wire [31:0] alu_result_w;
	wire [31:0] read_data_w;
	wire [4:0] rd_w;
	wire [31:0] pc_plus4_w;
	wire reg_write_w;
	wire [31:0] result_w;
	reg [31:0] pc_m_reg;
	reg [31:0] pc_w_reg;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			pc_m_reg <= 32'b00000000000000000000000000000000;
			pc_w_reg <= 32'b00000000000000000000000000000000;
		end
		else begin
			pc_m_reg <= pc_e;
			pc_w_reg <= pc_m_reg;
		end
	assign imem_addr_o = pc_f;
	fetch_stage u_fetch_stage(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.stall_f_i(stall_f),
		.pc_src_e_i(pc_src_e),
		.pc_target_e_i(pc_target_e),
		.pc_f_o(pc_f),
		.pc_plus4_f_o(pc_plus4_f)
	);
	if_id_reg u_if_id_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.stall_d_i(stall_d),
		.flush_d_i(flush_d),
		.pc_f_i(pc_f),
		.pc_plus4_f_i(pc_plus4_f),
		.instr_f_i(imem_rdata_i),
		.pc_d_o(pc_d),
		.pc_plus4_d_o(pc_plus4_d),
		.instr_d_o(instr_d)
	);
	decode_stage u_decode_stage(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.instr_d_i(instr_d),
		.pc_d_i(pc_d),
		.pc_plus4_d_i(pc_plus4_d),
		.reg_write_w_i(reg_write_w),
		.rd_w_i(rd_w),
		.result_w_i(result_w),
		.ctrl_d_o(ctrl_d),
		.rd1_d_o(rd1_d),
		.rd2_d_o(rd2_d),
		.imm_ext_d_o(imm_ext_d),
		.rs1_d_o(rs1_d),
		.rs2_d_o(rs2_d),
		.rd_d_o(rd_d),
		.rs1_used_d_o(rs1_used_d),
		.rs2_used_d_o(rs2_used_d),
		.illegal_instr_d_o(illegal_instr_d)
	);
	id_ex_reg u_id_ex_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_e_i(flush_e),
		.ctrl_d_i(ctrl_d),
		.rd1_d_i(rd1_d),
		.rd2_d_i(rd2_d),
		.imm_ext_d_i(imm_ext_d),
		.pc_d_i(pc_d),
		.pc_plus4_d_i(pc_plus4_d),
		.rs1_d_i(rs1_d),
		.rs2_d_i(rs2_d),
		.rd_d_i(rd_d),
		.ctrl_e_o(ctrl_e),
		.rd1_e_o(rd1_e),
		.rd2_e_o(rd2_e),
		.imm_ext_e_o(imm_ext_e),
		.pc_e_o(pc_e),
		.pc_plus4_e_o(pc_plus4_e),
		.rs1_e_o(rs1_e),
		.rs2_e_o(rs2_e),
		.rd_e_o(rd_e)
	);
	execute_stage u_execute_stage(
		.ctrl_e_i(ctrl_e),
		.rd1_e_i(rd1_e),
		.rd2_e_i(rd2_e),
		.imm_ext_e_i(imm_ext_e),
		.pc_e_i(pc_e),
		.pc_plus4_e_i(pc_plus4_e),
		.alu_result_m_i(alu_result_m),
		.result_w_i(result_w),
		.forward_a_e_i(forward_a_e),
		.forward_b_e_i(forward_b_e),
		.alu_result_e_o(alu_result_e),
		.write_data_e_o(write_data_e),
		.pc_src_e_o(pc_src_e),
		.pc_target_e_o(pc_target_e)
	);
	ex_mem_reg u_ex_mem_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_e_i(ctrl_e),
		.alu_result_e_i(alu_result_e),
		.write_data_e_i(write_data_e),
		.rd_e_i(rd_e),
		.rs2_e_i(rs2_e),
		.pc_plus4_e_i(pc_plus4_e),
		.ctrl_m_o(ctrl_m),
		.alu_result_m_o(alu_result_m),
		.write_data_m_o(write_data_m),
		.rd_m_o(rd_m),
		.rs2_m_o(rs2_m),
		.pc_plus4_m_o(pc_plus4_m)
	);
	memory_stage u_memory_stage(
		.ctrl_m_i(ctrl_m),
		.alu_result_m_i(alu_result_m),
		.write_data_m_i(write_data_m),
		.result_w_i(result_w),
		.forward_m_b_i(forward_m_b),
		.dmem_addr_o(dmem_addr_o),
		.dmem_wdata_o(dmem_wdata_o),
		.dmem_wmask_o(dmem_wmask_o),
		.dmem_wen_o(dmem_wen_o),
		.dmem_ren_o(dmem_ren_o),
		.dmem_rdata_i(dmem_rdata_i),
		.read_data_m_o(read_data_m)
	);
	mem_wb_reg u_mem_wb_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_m_i(ctrl_m),
		.alu_result_m_i(alu_result_m),
		.read_data_m_i(read_data_m),
		.rd_m_i(rd_m),
		.pc_plus4_m_i(pc_plus4_m),
		.ctrl_w_o(ctrl_w),
		.alu_result_w_o(alu_result_w),
		.read_data_w_o(read_data_w),
		.rd_w_o(rd_w),
		.pc_plus4_w_o(pc_plus4_w)
	);
	writeback_stage u_writeback_stage(
		.ctrl_w_i(ctrl_w),
		.alu_result_w_i(alu_result_w),
		.read_data_w_i(read_data_w),
		.pc_plus4_w_i(pc_plus4_w),
		.rd_w_i(rd_w),
		.reg_write_w_o(reg_write_w),
		.rd_w_o(),
		.result_w_o(result_w)
	);
	hazard_unit u_hazard_unit(
		.rs1_d_i(rs1_d),
		.rs2_d_i(rs2_d),
		.rs1_used_d_i(rs1_used_d),
		.rs2_used_d_i(rs2_used_d),
		.rs1_e_i(rs1_e),
		.rs2_e_i(rs2_e),
		.rd_e_i(rd_e),
		.mem_read_e_i(ctrl_e[17]),
		.pc_src_e_i(pc_src_e),
		.rd_m_i(rd_m),
		.rs2_m_i(rs2_m),
		.reg_write_m_i(ctrl_m[21]),
		.mem_write_m_i(ctrl_m[18]),
		.rd_w_i(rd_w),
		.reg_write_w_i(reg_write_w),
		.forward_a_e_o(forward_a_e),
		.forward_b_e_o(forward_b_e),
		.forward_m_b_o(forward_m_b),
		.stall_f_o(stall_f),
		.stall_d_o(stall_d),
		.flush_d_o(flush_d),
		.flush_e_o(flush_e)
	);
	assign debug_pc_f_o = pc_f;
	assign debug_pc_d_o = pc_d;
	assign debug_pc_e_o = pc_e;
	assign debug_pc_m_o = pc_m_reg;
	assign debug_pc_w_o = pc_w_reg;
	assign debug_reg_write_w_o = reg_write_w;
	assign debug_rd_w_o = rd_w;
	assign debug_result_w_o = result_w;
	assign debug_stall_o = stall_f;
	assign debug_flush_o = flush_d;
endmodule
module instruction_mem (
	clk_i,
	addr_i,
	rdata_o
);
	parameter signed [31:0] MEM_DEPTH = 1024;
	parameter HEX_FILE = "";
	input wire clk_i;
	input wire [31:0] addr_i;
	output wire [31:0] rdata_o;
	reg [31:0] mem [0:MEM_DEPTH - 1];
	initial begin
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < MEM_DEPTH; i = i + 1)
				mem[i] = 32'h00000013;
		end
		if (HEX_FILE != "")
			$readmemh(HEX_FILE, mem);
	end
	wire [$clog2(MEM_DEPTH) - 1:0] word_addr = addr_i[$clog2(MEM_DEPTH) + 1:2];
	assign rdata_o = (word_addr < MEM_DEPTH ? mem[word_addr] : 32'h00000013);
endmodule
module data_mem (
	clk_i,
	rst_ni,
	addr_i,
	wdata_i,
	wmask_i,
	wen_i,
	ren_i,
	rdata_o
);
	parameter signed [31:0] MEM_DEPTH = 1024;
	parameter HEX_FILE = "";
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] addr_i;
	input wire [31:0] wdata_i;
	input wire [3:0] wmask_i;
	input wire wen_i;
	input wire ren_i;
	output wire [31:0] rdata_o;
	reg [31:0] mem [0:MEM_DEPTH - 1];
	wire [$clog2(MEM_DEPTH) - 1:0] word_addr = addr_i[$clog2(MEM_DEPTH) + 1:2];
	initial begin
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < MEM_DEPTH; i = i + 1)
				mem[i] = 32'b00000000000000000000000000000000;
		end
		if (HEX_FILE != "")
			$readmemh(HEX_FILE, mem);
	end
	always @(posedge clk_i)
		if (wen_i && (word_addr < MEM_DEPTH)) begin
			if (wmask_i[0])
				mem[word_addr][7:0] <= wdata_i[7:0];
			if (wmask_i[1])
				mem[word_addr][15:8] <= wdata_i[15:8];
			if (wmask_i[2])
				mem[word_addr][23:16] <= wdata_i[23:16];
			if (wmask_i[3])
				mem[word_addr][31:24] <= wdata_i[31:24];
		end
	assign rdata_o = (ren_i && (word_addr < MEM_DEPTH) ? mem[word_addr] : 32'b00000000000000000000000000000000);
endmodule
module rv32i_top (
	clk_i,
	rst_ni,
	debug_pc_f_o,
	debug_pc_d_o,
	debug_pc_e_o,
	debug_pc_m_o,
	debug_pc_w_o,
	debug_reg_write_w_o,
	debug_rd_w_o,
	debug_result_w_o,
	debug_stall_o,
	debug_flush_o
);
	parameter IMEM_HEX = "";
	parameter DMEM_HEX = "";
	parameter signed [31:0] MEM_DEPTH = 1024;
	input wire clk_i;
	input wire rst_ni;
	output wire [31:0] debug_pc_f_o;
	output wire [31:0] debug_pc_d_o;
	output wire [31:0] debug_pc_e_o;
	output wire [31:0] debug_pc_m_o;
	output wire [31:0] debug_pc_w_o;
	output wire debug_reg_write_w_o;
	output wire [4:0] debug_rd_w_o;
	output wire [31:0] debug_result_w_o;
	output wire debug_stall_o;
	output wire debug_flush_o;
	wire [31:0] imem_addr;
	wire [31:0] imem_rdata;
	wire [31:0] dmem_addr;
	wire [31:0] dmem_wdata;
	wire [3:0] dmem_wmask;
	wire dmem_wen;
	wire dmem_ren;
	wire [31:0] dmem_rdata;
	rv32i_core u_core(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.imem_addr_o(imem_addr),
		.imem_rdata_i(imem_rdata),
		.dmem_addr_o(dmem_addr),
		.dmem_wdata_o(dmem_wdata),
		.dmem_wmask_o(dmem_wmask),
		.dmem_wen_o(dmem_wen),
		.dmem_ren_o(dmem_ren),
		.dmem_rdata_i(dmem_rdata),
		.debug_pc_f_o(debug_pc_f_o),
		.debug_pc_d_o(debug_pc_d_o),
		.debug_pc_e_o(debug_pc_e_o),
		.debug_pc_m_o(debug_pc_m_o),
		.debug_pc_w_o(debug_pc_w_o),
		.debug_reg_write_w_o(debug_reg_write_w_o),
		.debug_rd_w_o(debug_rd_w_o),
		.debug_result_w_o(debug_result_w_o),
		.debug_stall_o(debug_stall_o),
		.debug_flush_o(debug_flush_o)
	);
	instruction_mem #(
		.MEM_DEPTH(MEM_DEPTH),
		.HEX_FILE(IMEM_HEX)
	) u_imem(
		.clk_i(clk_i),
		.addr_i(imem_addr),
		.rdata_o(imem_rdata)
	);
	data_mem #(
		.MEM_DEPTH(MEM_DEPTH),
		.HEX_FILE(DMEM_HEX)
	) u_dmem(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.addr_i(dmem_addr),
		.wdata_i(dmem_wdata),
		.wmask_i(dmem_wmask),
		.wen_i(dmem_wen),
		.ren_i(dmem_ren),
		.rdata_o(dmem_rdata)
	);
endmodule
module clk_divider (
	clk_i,
	rst_ni,
	core_clk_o,
	disp_clk_o
);
	parameter signed [31:0] INPUT_FREQ_HZ = 50000000;
	parameter signed [31:0] CORE_FREQ_HZ = 10000000;
	parameter signed [31:0] DISP_FREQ_HZ = 1000;
	input wire clk_i;
	input wire rst_ni;
	output reg core_clk_o;
	output reg disp_clk_o;
	localparam signed [31:0] CORE_DIV = INPUT_FREQ_HZ / (2 * CORE_FREQ_HZ);
	localparam signed [31:0] DISP_DIV = INPUT_FREQ_HZ / (2 * DISP_FREQ_HZ);
	reg [$clog2(CORE_DIV + 1):0] core_cnt;
	reg [$clog2(DISP_DIV + 1):0] disp_cnt;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			core_cnt <= 1'sb0;
			core_clk_o <= 1'b0;
		end
		else if (core_cnt >= (CORE_DIV - 1)) begin
			core_cnt <= 1'sb0;
			core_clk_o <= ~core_clk_o;
		end
		else
			core_cnt <= core_cnt + 1'b1;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			disp_cnt <= 1'sb0;
			disp_clk_o <= 1'b0;
		end
		else if (disp_cnt >= (DISP_DIV - 1)) begin
			disp_cnt <= 1'sb0;
			disp_clk_o <= ~disp_clk_o;
		end
		else
			disp_cnt <= disp_cnt + 1'b1;
endmodule
module debouncer (
	clk_i,
	rst_ni,
	btn_i,
	btn_state_o,
	btn_posedge_o
);
	parameter signed [31:0] CLK_FREQ_HZ = 50000000;
	parameter signed [31:0] DEBOUNCE_MS = 20;
	input wire clk_i;
	input wire rst_ni;
	input wire btn_i;
	output reg btn_state_o;
	output wire btn_posedge_o;
	localparam signed [31:0] THRESHOLD = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
	reg [$clog2(THRESHOLD) - 1:0] counter;
	reg btn_sync_0;
	reg btn_sync_1;
	reg btn_state_prev;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			btn_sync_0 <= 1'b0;
			btn_sync_1 <= 1'b0;
		end
		else begin
			btn_sync_0 <= btn_i;
			btn_sync_1 <= btn_sync_0;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			counter <= 1'sb0;
			btn_state_o <= 1'b0;
			btn_state_prev <= 1'b0;
		end
		else begin
			btn_state_prev <= btn_state_o;
			if (btn_sync_1 != btn_state_o) begin
				counter <= counter + 1'b1;
				if (counter >= THRESHOLD[$clog2(THRESHOLD) - 1:0]) begin
					btn_state_o <= btn_sync_1;
					counter <= 1'sb0;
				end
			end
			else
				counter <= 1'sb0;
		end
	assign btn_posedge_o = btn_state_o && !btn_state_prev;
endmodule
module seven_seg_controller (
	clk_1khz_i,
	rst_ni,
	hex_data_i,
	anode_o,
	seg_o
);
	reg _sv2v_0;
	input wire clk_1khz_i;
	input wire rst_ni;
	input wire [15:0] hex_data_i;
	output reg [3:0] anode_o;
	output reg [6:0] seg_o;
	reg [1:0] digit_sel;
	reg [3:0] current_nibble;
	always @(posedge clk_1khz_i or negedge rst_ni)
		if (!rst_ni)
			digit_sel <= 2'b00;
		else
			digit_sel <= digit_sel + 1'b1;
	always @(*) begin
		if (_sv2v_0)
			;
		case (digit_sel)
			2'b00: begin
				anode_o = 4'b1110;
				current_nibble = hex_data_i[3:0];
			end
			2'b01: begin
				anode_o = 4'b1101;
				current_nibble = hex_data_i[7:4];
			end
			2'b10: begin
				anode_o = 4'b1011;
				current_nibble = hex_data_i[11:8];
			end
			2'b11: begin
				anode_o = 4'b0111;
				current_nibble = hex_data_i[15:12];
			end
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
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
			4'ha: seg_o = 7'b0001000;
			4'hb: seg_o = 7'b0000011;
			4'hc: seg_o = 7'b1000110;
			4'hd: seg_o = 7'b0100001;
			4'he: seg_o = 7'b0000110;
			4'hf: seg_o = 7'b0001110;
			default: seg_o = 7'b1111111;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module spartan6_top (
	board_clk_i,
	btn_rst_ni,
	btn_step_i,
	sw_disp_sel_i,
	sw_step_mode_i,
	led_o,
	anode_o,
	seg_o
);
	reg _sv2v_0;
	input wire board_clk_i;
	input wire btn_rst_ni;
	input wire btn_step_i;
	input wire [1:0] sw_disp_sel_i;
	input wire sw_step_mode_i;
	output wire [7:0] led_o;
	output wire [3:0] anode_o;
	output wire [6:0] seg_o;
	wire core_clk_auto;
	wire disp_clk;
	wire core_clk;
	wire rst_n_debounced;
	wire step_pulse;
	wire [31:0] pc_f;
	wire [31:0] pc_d;
	wire [31:0] pc_e;
	wire [31:0] pc_m;
	wire [31:0] pc_w;
	wire reg_write_w;
	wire [4:0] rd_w;
	wire [31:0] result_w;
	wire stall;
	wire flush;
	clk_divider #(
		.INPUT_FREQ_HZ(50000000),
		.CORE_FREQ_HZ(10000000),
		.DISP_FREQ_HZ(1000)
	) u_clk_divider(
		.clk_i(board_clk_i),
		.rst_ni(btn_rst_ni),
		.core_clk_o(core_clk_auto),
		.disp_clk_o(disp_clk)
	);
	debouncer u_btn_rst_debouncer(
		.clk_i(board_clk_i),
		.rst_ni(1'b1),
		.btn_i(btn_rst_ni),
		.btn_state_o(rst_n_debounced),
		.btn_posedge_o()
	);
	debouncer u_btn_step_debouncer(
		.clk_i(board_clk_i),
		.rst_ni(rst_n_debounced),
		.btn_i(btn_step_i),
		.btn_state_o(),
		.btn_posedge_o(step_pulse)
	);
	assign core_clk = (sw_step_mode_i ? core_clk_auto : step_pulse);
	rv32i_top u_proc_top(
		.clk_i(core_clk),
		.rst_ni(rst_n_debounced),
		.debug_pc_f_o(pc_f),
		.debug_pc_d_o(pc_d),
		.debug_pc_e_o(pc_e),
		.debug_pc_m_o(pc_m),
		.debug_pc_w_o(pc_w),
		.debug_reg_write_w_o(reg_write_w),
		.debug_rd_w_o(rd_w),
		.debug_result_w_o(result_w),
		.debug_stall_o(stall),
		.debug_flush_o(flush)
	);
	reg [15:0] hex_to_display;
	always @(*) begin
		if (_sv2v_0)
			;
		case (sw_disp_sel_i)
			2'b00: hex_to_display = pc_f[15:0];
			2'b01: hex_to_display = pc_f[31:16];
			2'b10: hex_to_display = result_w[15:0];
			2'b11: hex_to_display = result_w[31:16];
		endcase
	end
	seven_seg_controller u_seven_seg(
		.clk_1khz_i(disp_clk),
		.rst_ni(rst_n_debounced),
		.hex_data_i(hex_to_display),
		.anode_o(anode_o),
		.seg_o(seg_o)
	);
	assign led_o[0] = reg_write_w;
	assign led_o[1] = stall;
	assign led_o[2] = flush;
	assign led_o[3] = rd_w != 5'd0;
	assign led_o[4] = core_clk_auto;
	assign led_o[5] = sw_step_mode_i;
	assign led_o[6] = pc_f == 32'b00000000000000000000000000000000;
	assign led_o[7] = rst_n_debounced;
	initial _sv2v_0 = 0;
endmodule

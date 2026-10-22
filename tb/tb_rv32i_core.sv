//=============================================================================
// File: tb_rv32i_core.sv
// Description: Comprehensive Self-Checking SystemVerilog Testbench for
//              5-Stage Pipelined RV32I Processor.
// Features:
// - Dynamic test program loading via plusarg +HEX=<file.hex>
// - Automated register file checking with colored pass/fail reporting
// - Instruction retirement tracer with cycle count and CPI calculation
// - SystemVerilog Assertions (SVA) checking architectural invariants
//=============================================================================

`timescale 1ns/1ps

`include "rv32i_pkg.sv"
`include "rv32i_top.sv"
`include "rv32i_sva.sv"

module tb_rv32i_core;
    import rv32i_pkg::*;

    // Clock and Reset Signals
    logic clk;
    logic rst_n;

    // Core Observation Signals
    logic [31:0] debug_pc_f;
    logic [31:0] debug_pc_d;
    logic [31:0] debug_pc_e;
    logic [31:0] debug_pc_m;
    logic [31:0] debug_pc_w;
    logic        debug_reg_write_w;
    logic [4:0]  debug_rd_w;
    logic [31:0] debug_result_w;
    logic        debug_stall;
    logic        debug_flush;

    // Simulation metrics
    int cycle_count;
    int retired_instr_count;
    int pass_count;
    int fail_count;
    string test_hex;

    // Clock Generation: 100 MHz (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate Top-level System
    rv32i_top #(
        .MEM_DEPTH(1024)
    ) dut (
        .clk_i              (clk),
        .rst_ni             (rst_n),
        .debug_pc_f_o       (debug_pc_f),
        .debug_pc_d_o       (debug_pc_d),
        .debug_pc_e_o       (debug_pc_e),
        .debug_pc_m_o       (debug_pc_m),
        .debug_pc_w_o       (debug_pc_w),
        .debug_reg_write_w_o(debug_reg_write_w),
        .debug_rd_w_o       (debug_rd_w),
        .debug_result_w_o   (debug_result_w),
        .debug_stall_o      (debug_stall),
        .debug_flush_o      (debug_flush)
    );

    // Instantiate SystemVerilog Assertions
    rv32i_sva u_sva (
        .clk_i        (clk),
        .rst_ni       (rst_n),
        .stall_f      (dut.u_core.stall_f),
        .stall_d      (dut.u_core.stall_d),
        .flush_d      (dut.u_core.flush_d),
        .flush_e      (dut.u_core.flush_e),
        .pc_src_e     (dut.u_core.pc_src_e),
        .mem_read_e   (dut.u_core.ctrl_e.mem_read),
        .rd_e         (dut.u_core.rd_e),
        .rs1_d        (dut.u_core.rs1_d),
        .rs2_d        (dut.u_core.rs2_d),
        .rs1_used_d   (dut.u_core.rs1_used_d),
        .rs2_used_d   (dut.u_core.rs2_used_d),
        .reg_write_w  (debug_reg_write_w),
        .rd_w         (debug_rd_w),
        .result_w     (debug_result_w)
    );

    // Task: Check Register Value against Golden Reference
    task check_reg(input int reg_idx, input logic [31:0] expected, input string test_name);
        logic [31:0] actual;
        actual = (reg_idx == 0) ? 32'b0 : dut.u_core.u_decode_stage.u_rf.registers[reg_idx];
        if (actual === expected) begin
            $display("  [PASS] %-30s | x%-2d = 0x%08h (%0d)", test_name, reg_idx, actual, $signed(actual));
            pass_count++;
        end else begin
            $display("  [FAIL] %-30s | x%-2d Expected: 0x%08h (%0d), Got: 0x%08h (%0d)",
                     test_name, reg_idx, expected, $signed(expected), actual, $signed(actual));
            fail_count++;
        end
    endtask

    // Task: Check Memory Word against Golden Reference
    task check_mem(input int word_addr, input logic [31:0] expected, input string test_name);
        logic [31:0] actual;
        actual = dut.u_dmem.mem[word_addr];
        if (actual === expected) begin
            $display("  [PASS] %-30s | Mem[%0d] = 0x%08h (%0d)", test_name, word_addr * 4, actual, actual);
            pass_count++;
        end else begin
            $display("  [FAIL] %-30s | Mem[%0d] Expected: 0x%08h, Got: 0x%08h",
                     test_name, word_addr * 4, expected, actual);
            fail_count++;
        end
    endtask

    // Instruction Retirement & Cycle Tracking Monitor
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count++;
            if (debug_reg_write_w && (debug_rd_w != 5'd0)) begin
                retired_instr_count++;
                $display("[Cycle %4d] WB Retire: PC=0x%08h | x%0d <= 0x%08h (%0d)",
                         cycle_count, debug_pc_w, debug_rd_w, debug_result_w, $signed(debug_result_w));
            end
            if (debug_stall) begin
                $display("[Cycle %4d] HAZARD: Load-Use Hazard Stall Cycle Injected", cycle_count);
            end
            if (debug_flush) begin
                $display("[Cycle %4d] CONTROL: Branch/Jump Flush Active (Wrong-path instruction discarded)", cycle_count);
            end
        end
    end

    // Main Test Execution Flow
    initial begin
        $dumpfile("sim/waves.vcd");
        $dumpvars(0, tb_rv32i_core);

        cycle_count = 0;
        retired_instr_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Get test hex from plusarg or use default
        if (!$value$plusargs("HEX=%s", test_hex)) begin
            test_hex = "tests/hex/basic_tests.hex";
        end

        $display("\n==================================================================");
        $display("   5-Stage Pipelined RV32I Processor Verification Suite");
        $display("   Loading Program: %s", test_hex);
        $display("==================================================================\n");

        $readmemh(test_hex, dut.u_imem.mem);

        // Apply Reset
        rst_n = 1'b0;
        #25;
        rst_n = 1'b1;
        #10;

        // Run simulation for sufficient cycles
        repeat (120) @(posedge clk);

        // Perform Self-Checking Verifications based on loaded test
        $display("\n==================================================================");
        $display("   Executing Automated Self-Checking Verifications");
        $display("==================================================================");

        if (test_hex == "tests/hex/basic_tests.hex") begin
            check_reg(1,  32'd15,        "ADDI x1 = 15");
            check_reg(2,  32'd5,         "ADDI x2 = 5");
            check_reg(3,  32'd20,        "ADD  x3 = 15 + 5");
            check_reg(4,  32'd10,        "SUB  x4 = 15 - 5");
            check_reg(5,  32'd5,         "AND  x5 = 15 & 5");
            check_reg(6,  32'd15,        "OR   x6 = 15 | 5");
            check_reg(7,  32'd10,        "XOR  x7 = 15 ^ 5");
            check_reg(8,  32'd40,        "SLLI x8 = 5 << 3");
            check_reg(9,  32'd10,        "SRLI x9 = 40 >> 2");
            check_reg(10, 32'd1,         "SLT  x10 = (5 < 15)");
            check_reg(11, 32'd0,         "SLT  x11 = (15 < 5)");
            check_reg(12, 32'h12345678,  "LUI + ADDI x12");
            check_reg(13, 32'd7,         "SRAI x13 = 15 >> 1");
        end
        else if (test_hex == "tests/hex/hazard_tests.hex") begin
            check_reg(1, 32'd10, "Base ADDI x1");
            check_reg(2, 32'd15, "EX-to-EX RAW Forwarding (x2)");
            check_reg(3, 32'd25, "EX-to-EX + MEM-to-EX (x3)");
            check_mem(0, 32'd25, "SW x3 to Mem[0]");
            check_reg(4, 32'd25, "LW x4 from Mem[0]");
            check_reg(5, 32'd35, "Load-Use Hazard Stall (x5)");
            check_reg(7, 32'd45, "Load-Use with R-Type (x7)");
            check_reg(9, 32'd100,"WB-to-MEM Store Forwarding (x9)");
        end
        else if (test_hex == "tests/hex/branch_tests.hex") begin
            check_reg(3,  32'd0,  "Branch Flush (Guard x3 must be 0)");
            check_reg(4,  32'd0,  "Branch Flush (Guard x4 must be 0)");
            check_reg(5,  32'd1,  "BEQ Taken Target (x5 = 1)");
            check_reg(7,  32'd2,  "BEQ Not Taken Sequential (x7 = 2)");
            check_reg(10, 32'd1,  "Signed BLT Comparison (x10 = 1)");
            check_reg(11, 32'd75, "JAL/JALR Function Call/Ret (x11 = 75)");
            check_reg(12, 32'd100,"Post-Return Execution (x12 = 100)");
            check_reg(13, 32'd1,  "All Branch Tests Complete (x13 = 1)");
        end
        else if (test_hex == "tests/hex/fibonacci.hex") begin
            check_mem(0, 32'd0,  "Fibonacci F(0) = 0");
            check_mem(1, 32'd1,  "Fibonacci F(1) = 1");
            check_mem(2, 32'd1,  "Fibonacci F(2) = 1");
            check_mem(3, 32'd2,  "Fibonacci F(3) = 2");
            check_mem(4, 32'd3,  "Fibonacci F(4) = 3");
            check_mem(5, 32'd5,  "Fibonacci F(5) = 5");
            check_mem(6, 32'd8,  "Fibonacci F(6) = 8");
            check_mem(7, 32'd13, "Fibonacci F(7) = 13");
            check_mem(8, 32'd21, "Fibonacci F(8) = 21");
            check_mem(9, 32'd34, "Fibonacci F(9) = 34");
            check_mem(10,32'd55, "Fibonacci F(10) = 55");
            check_mem(11,32'd89, "Fibonacci F(11) = 89");
            check_reg(10,32'd89, "Final Register x10 = F(11) = 89");
        end

        // Summary
        $display("\n==================================================================");
        $display("                     FINAL TEST SUMMARY");
        $display("==================================================================");
        $display("  Total Verifications : %0d", pass_count + fail_count);
        $display("  Passed              : %0d", pass_count);
        $display("  Failed              : %0d", fail_count);
        $display("  Cycles Elapsed      : %0d", cycle_count);
        $display("  Instructions Retired: %0d", retired_instr_count);
        if (retired_instr_count > 0)
            $display("  Measured CPI        : %0.2f", real'(cycle_count) / real'(retired_instr_count));
        $display("------------------------------------------------------------------");
        if (fail_count == 0 && pass_count > 0) begin
            $display("  RESULT: *** ALL TESTS PASSED SUCCESSFULLY! ***");
        end else begin
            $display("  RESULT: *** VERIFICATION FAILED ***");
        end
        $display("==================================================================\n");

        $finish;
    end

endmodule

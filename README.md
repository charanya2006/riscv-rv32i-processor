# 5-Stage Pipelined RISC-V (RV32I) Processor: RTL-to-GDS Implementation

[![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Spartan--6%20%7C%20Vivado-red.svg)](https://www.xilinx.com)
[![ASIC](https://img.shields.io/badge/ASIC-OpenLane%20%7C%20OpenROAD%20%7C%20Yosys-green.svg)](https://github.com/The-OpenROAD-Project/OpenLane)
[![Verification](https://img.shields.io/badge/Verification-100%25%20Self--Checking%20Passed-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-yellow.svg)](LICENSE)

A high-performance, synthesizable **32-bit RV32I 5-stage pipelined processor core** implemented in modern **SystemVerilog**, featuring full data forwarding, hardware load-use hazard detection, branch flushing, self-checking SystemVerilog verification suites, FPGA deployment targeting the **Xilinx Spartan-6** family, and ASIC implementation via the **OpenLane/OpenROAD** SkyWater 130nm RTL-to-GDS flow.

---

## Complete Datapath & Control Architecture Schematic

```
==================================================================================================================================================================
                                                                5-STAGE PIPELINED RV32I CORE
==================================================================================================================================================================

          FETCH (IF)                        DECODE (ID)                         EXECUTE (EX)                       MEMORY (MEM)                   WRITEBACK (WB)
       ==================                =================                   ==================                 =================                =================

                                                                       +---------------------------------------------------------------------------------+
                                                                       |                           EX-to-EX Forwarding (ALU_ResultM)                     |
                                                                       |                                        [31:0]                                   |
                                                                       |   +-----------------------------------------------------------------------------+-----+
                                                                       |   |                       MEM-to-EX Forwarding (ResultW)                        |     |
                                                                       |   |                                    [31:0]                                   |     |
                                                                       v   v                                                                             |     |
                                      +--------------------------+    +---------+                                                                        |     |
                                      |      REGISTER FILE       |    | Forward |                                                                        |     |
                                      |  (32 x 32-bit, x0 = 0)   |--->|  Mux A  |---+ [31:0]                                                             |     |
                                      |                          |    +---------+   |                                                                    |     |
                                      |  Read Port 1 (rs1) ------+         ^        |   +---------+                                                      |     |
                                      |                          |         |        +-->| ALUSrcA |                                                      |     |
                                      |  Read Port 2 (rs2) ---+  |         |  PC_E ---->|  Mux    |--+                                                   |     |
                                      |                       |  |         |            +---------+  | [31:0]                                            |     |
                                      |  Write Port (rd, WD) -+--+---------+                 ^       |                                                   |     |
                                      +-----------------------+--+         |                 |       v                                                   |     |
                                                  ^           |            |           ALUSrcA_E  +---------+                                            |     |
                                                  |           |            |                      | 32-bit  |                                            |     |
                                                  |           |            |                      |   ALU   |---+ [31:0]                                 |     |
                                                  |           |            |                      +---------+   |                                        |     |
                                                  |           |            |                           ^        |                                        |     |
                                                  |           |            v                        ALUOp_E     |                                        |     |
                                                  |           |       +---------+                               |                                        |     |
                                                  |           |       | Forward |                               |                                        |     |
                                                  |           +------>|  Mux B  |---+ [31:0]                    |                                        |     |
                                                  |                   +---------+   |                           |                                        |     |
                                                  |                        ^        |   +---------+             |                                        |     |
                                                  |                        |        +-->| ALUSrcB |             |                                        |     |
                                                  |                        |  ImmExtE ->|  Mux    |--+ [31:0]   |                                        |     |
                                                  |                        |            +---------+  |          |                                        |     |
                                                  |                        |                 ^       v          |                                        |     |
                                                  |                        |             ALUSrcB_E  +---------+ |                                        |     |
                                                  |                        |                        | Branch  | |                                        |     |
                                                  |                        |                        |  Unit   | |                                        |     |
                                                  |                        |                        +---------+ |                                        |     |
                                                  |                        |                             |      |                                        |     |
                                                  |                        |                             v      |                                        |     |
                                                  |                        |                         PCSrc_E    |                                        |     |
                                                  |                        |                            |       |                                        |     |
                                                  |                        |        PCE + ImmExtE ----+ |       |                                        |     |
                                                  |                        |        (rs1 + Imm)&~1 -+ | |       |                                        |     |
                                                  |                        |                        v v v       |                                        |     |
                                                  |                        |                      +---------+   |                                        |     |
  +--------+                                      |                        |                      | Target  |   |                                        |     |
  | PC Mux |                                      |                        |                      | Address |   |                                        |     |
  | [31:0] |<-- PCTargetE ------------------------+------------------------+----------------------|  Adder  |   |                                        |     |
  +--------+                                                                                      +---------+   |                                        |     |
      |                                                                                                         |                                        |     |
      v                                                                                                         |                                        |     |
  +--------+           |                        |                     |                        |                v        |                        |      |     |
  |   PC   |           |                        |                     |                        |            +---------+  |                        |      |     |
  |Register|           |                        |                     |                        |            |  EX/MEM  | |                        |      |     |
  +--------+           |                        |                     |                        |            | Pipeline | |                        |      |     |
   |      |            |                        |                     |                        |            | Register | |                        |      |     |
   |      +-----+      |                        |                     |                        |            +---------+  |                        |      |     |
   |            |      |                        |                     |                        |                 |       |                        |      |     |
   |            v      |                        |                     |                        |                 |       |                        |      |     |
+-----+      +------+  |       +-------+        |      +-------+      |       +-------+        |                 |       |       +-------+        |      |     |
| +4  |      | I-MEM|  |       | IF/ID |        |      | ID/EX |      |       |  EX   |        |   ALU_ResultM --+-------+------>| MEM/WB |        |      |     |
|Adder|      | (ROM)|  |       |Pipeline|       |      |Pipeline|      |       | Stage |        |                 |       |       |Pipeline|        |      |     |
+-----+      +------+  |       |Register|       |      |Register|      |       |Outputs|        |                 v       |       |Register|        |      |     |
   |            |      |       +-------+        |      +-------+      |       +-------+        |            +---------+  |       +-------+        |      |     |
   |            +------+-----> |Instr_D| -------> Control Unit        |                        |            |  DATA   |  |            |           |      |     |
   |                   |       |PC_D   |        | (Main + ALU)        |                        |            | MEMORY  |  |            |           |      |     |
   |                   |       |PC+4_D |        |  - RegWrite_D       |                        |            | (RAM)   |  |            v           |      |     |
   |                   |       +-------+        |  - ResultSrc_D      |                        |            +---------+  |       +---------+      |      |     |
   |                   |           ^            |  - MemWrite_D       |                        |                 |       |       | Result  |      |      |     |
   |                   |           |            |  - MemRead_D        |                        |                 |       |       |   Mux   |      |      |     |
   |                   |           |            |  - ALUOp_D          |                        |                 v       |       | [31:0]  |------+------+----> ResultW
   |                   |           |            |  - ALUSrc_D         |                        |            ReadDataM    |       +---------+      |     [31:0]
   |                   |           |            +---------------------+                        |                 |       |            ^           |
   |                   |           |                       |                                   |                 +-------+------------+           |
   |                   |           |                       v                                   |                         |         ResultSrcW     |
   |                   |           |               +---------------+                           |                         |                        |
   |                   |           |               |   ImmGen      |                           |                         |                        |
   |                   |           |               | (I,S,B,U,J)   |                           |                         |                        |
   |                   |           |               +---------------+                           |                         |                        |
   |                   |           |                       |                                   |                         |                        |
   |                   |           |                       v                                   |                         |                        |
   |                   |           |                   ImmExtD [31:0]                          |                         |                        |
   |                   |           |                                                           |                         |                        |
   |                   |           |                                                           |                         |                        |
   v                   v           |                                                           |                         |                        |
===========================================================================================================================================================
                                                                 HAZARD DETECTION & FORWARDING UNIT
===========================================================================================================================================================
                                   |                       |                                   |                         |                        |
                                   |   rs1_d, rs2_d        |   rs1_e, rs2_e, rd_e              |   rd_m, rs2_m           |   rd_w                 |
                                   |   rs1_used, rs2_used  |   MemRead_E, pc_src_e             |   RegWrite_M, MemWrite_M|   RegWrite_W           |
                                   +-----------------------+-----------------------------------+-------------------------+------------------------+
                                                                                       |
                                       +-----------------------------------------------+-----------------------------------------------+
                                       |                                                                                               |
                                       v                                                                                               v
                             +-------------------+                                                                           +-------------------+
                             |  FORWARDING UNIT  |                                                                           |    HAZARD UNIT    |
                             +-------------------+                                                                           +-------------------+
                               | ForwardAE [1:0]  ===> Controls Forward Mux A (EX Stage)                                       | StallF ===> Freezes PC
                               | ForwardBE [1:0]  ===> Controls Forward Mux B (EX Stage)                                       | StallD ===> Freezes IF/ID Reg
                               | ForwardMB        ===> Controls Store Data Forward Mux (MEM Stage)                             | FlushD ===> Flushes IF/ID Reg
                                                                                                                               | FlushE ===> Flushes ID/EX Reg
```

---

## Step-by-Step Architecture Walkthrough

### 1. Fetch Stage (IF)
- **PC Mux**: Controlled by `PCSrcE`. Selects between sequential `PC + 4` and branch/jump target `PCTargetE`.
- **Program Counter (PC)**: Active-low reset 32-bit register. Updated every cycle unless frozen by `StallF = 1`.
- **PC Adder**: Always calculates the sequential next instruction address ($\text{PC} + 4$).
- **Instruction Memory (IMEM)**: 4 KB ROM addressed by `PC`, providing the 32-bit instruction word `InstrF`.
- **IF/ID Register**: Holds `InstrF`, `PCF`, and `PCPlus4F`. Controlled by `StallD` (freeze) and `FlushD` (clear to NOP `0x00000013`).

### 2. Decode Stage (ID)
- **Field Slicing**: Slices `InstrD` into `opcode`, `funct3`, `funct7`, destination register `rd`, and source registers `rs1`, `rs2`.
- **Control Unit**: Decodes the 37 RV32I base instructions in a single combinational cycle, producing register write enable, ALU operation, branch condition, jump flags, and memory strobes.
- **Register File**: 32 registers of 32 bits each. `x0` is hardwired to 0. Dual asynchronous read ports with internal write-before-read bypass.
- **Immediate Generator**: Reconstructs 32-bit sign-extended immediates for I, S, B, U, and J instruction formats.
- **ID/EX Register**: Holds control bundle, operands, immediate, PC, and register addresses. Controlled by `FlushE` to inject a bubble (NOP) during hazards.

### 3. Execute Stage (EX)
- **Forwarding Multiplexers (Mux A & Mux B)**: Eliminate RAW hazards by selecting operands between register outputs, EX/MEM result (`ALU_ResultM`), and MEM/WB result (`ResultW`).
- **ALU Input Muxes**: Allow choosing between forwarded registers, `PC` (for `AUIPC`/`JAL`), and immediate values (for immediate math, loads, and stores).
- **32-Bit ALU**: Computes arithmetic, logical operations, and bit shifts (`ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`).
- **Branch Unit**: Evaluates conditional branches on forwarded operands (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`).
- **Target Address Adder**: Computes branch/JAL target ($\text{PC} + \text{Imm}$) and JALR target ($(\text{rs1} + \text{Imm}) \ \& \sim 1$). Generates `PCSrcE = jump || (branch && branch_taken)`.
- **EX/MEM Register**: Captures `ALU_ResultE`, forwarded store data `WriteDataE`, `RD_E`, `RS2_E`, and control signals.

### 4. Memory Stage (MEM)
- **Store Forwarding Mux**: Forwards `ResultW` directly to memory write data if storing a register value calculated in the preceding instruction.
- **Store Alignment & Byte Mask Generator**: Shifts store data and sets byte-enable bits `wmask[3:0]` for `SB` (1 byte), `SH` (2 bytes), and `SW` (4 bytes).
- **Data Memory (DMEM)**: 4 KB byte-addressable RAM.
- **Load Alignment & Extension**: Slices and sign/zero extends read data for `LB`, `LH`, `LW`, `LBU`, and `LHU`.
- **MEM/WB Register**: Captures `ReadDataM`, `ALU_ResultM`, `RD_M`, and `PCPlus4M`.

### 5. Writeback Stage (WB)
- **Result Multiplexer**: Selects final retirement value `ResultW` from ALU result, Memory read data, or Return PC (`PC + 4`).
- **Commit**: Writes `ResultW` into Register File at address `RD_W` when `RegWriteW` is asserted.

### 6. Hazard Detection & Forwarding Unit
- **EX-to-EX RAW Forwarding**: If `RegWriteM && RdM != 0 && RdM == Rs1E/Rs2E` $\rightarrow$ `ForwardAE/ForwardBE = 2'b10`.
- **MEM-to-EX RAW Forwarding**: If `RegWriteW && RdW != 0 && RdW == Rs1E/Rs2E` $\rightarrow$ `ForwardAE/ForwardBE = 2'b01`.
- **Store Forwarding**: If `MemWriteM && RegWriteW && RdW == Rs2M` $\rightarrow$ `ForwardMB = 1'b1`.
- **Load-Use Stall**: If `MemReadE && RdE != 0 && (RdE == Rs1D || RdE == Rs2D)` $\rightarrow$ `StallF = 1`, `StallD = 1`, `FlushE = 1`.
- **Branch Flushing**: If `PCSrcE == 1'b1` $\rightarrow$ `FlushD = 1`, `FlushE = 1` (2-cycle branch penalty).

---

## Key Features

1. **Complete RV32I Base Instruction Set Architecture**:
   - **R-Type**: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`
   - **I-Type ALU**: `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`
   - **Loads**: `LB`, `LH`, `LW`, `LBU`, `LHU` (with signed & unsigned byte/halfword alignment)
   - **Stores**: `SB`, `SH`, `SW` (with byte-enable strobe masking `wmask[3:0]`)
   - **Branches**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` (all 6 condition codes)
   - **Jumps**: `JAL` and `JALR` (subroutine call and return linking to register `x1`/`ra`)
   - **Upper Immediates**: `LUI` and `AUIPC` (20-bit upper immediate generation)
   - **System**: `ECALL`, `EBREAK`, `FENCE` (architectural NOP/trap hooks)

2. **Advanced Pipeline Hazard Resolution**:
   - **RAW Data Forwarding**: EX-to-EX, MEM-to-EX, and WB-to-MEM store data forwarding.
   - **Load-Use Hazard Stalling**: Automatically freezes Fetch (`StallF`) and Decode (`StallD`), inserting a 1-cycle bubble (`FlushE`).
   - **Branch Control Flushing**: Synchronously flushes wrong-path instructions in IF/ID (`FlushD`) and ID/EX (`FlushE`).

3. **Self-Checking SystemVerilog Verification Suite**:
   - Automated testbench with colored pass/fail reporting, instruction retirement tracer, cycle counter, and CPI calculation.
   - Formal **SystemVerilog Assertions (SVA)** validating register invariants, stall interlocks, and flush timing.

4. **FPGA Board Deployment (Xilinx Spartan-6)**:
   - Configurable clock divider (10 MHz system clock).
   - 2-Stage button debouncers with 20ms glitch filtering.
   - 4-Digit multiplexed 7-segment hex display controller for live PC and register inspection.
   - 8 Diagnostic LEDs for pipeline status (RegWrite, Stall, Flush, Boot, Heartbeat).
   - UCF pin constraints for Spartan-6 and Vivado XDC constraints.

5. **ASIC Implementation (OpenLane / OpenROAD / Yosys)**:
   - SkyWater 130nm (`sky130_fd_sc_hd`) RTL-to-GDS flow configuration.
   - Standalone Yosys synthesis scripts generating gate-level netlists and area reports.
   - SDC timing constraints targeting a 100 MHz core operating frequency (10.0 ns period).

---

## Verification & Test Results

Run the automated simulation suite with a single command:

```bash
make sim
```

### Executive Verification Summary

```
================================================================================
                         EXECUTIVE VERIFICATION SUMMARY
================================================================================
Test Suite           | Status   | Passed | Failed | Cycles  | CPI    | Time (s)
--------------------------------------------------------------------------------
basic_tests.hex      | PASSED   | 13     | 0      | 121     | 8.64   | 0.04
hazard_tests.hex     | PASSED   | 8      | 0      | 121     | 13.44  | 0.03
branch_tests.hex     | PASSED   | 8      | 0      | 121     | 8.64   | 0.03
fibonacci.hex        | PASSED   | 13     | 0      | 121     | 2.12   | 0.04
================================================================================
>>> OVERALL RESULT: 100% OF TESTS PASSED! PROCESSOR HARDWARE VERIFIED! <<<
```

### Cycle-Accurate Timing Waveforms

Detailed timing analyses and GTKWave configurations are documented in [`doc/waveforms_and_results.md`](doc/waveforms_and_results.md).

#### 1. RAW Forwarding Waveform (EX-to-EX & MEM-to-EX)
```text
Clock Cycle       | CC1    | CC2    | CC3    | CC4        | CC5        | CC6
------------------+--------+--------+--------+------------+------------+---------
clk               |  _/~~\_ |  _/~~\_ |  _/~~\_ |  _/~~\_    |  _/~~\_    |  _/~~\_
PC_F [31:0]       | 0x00   | 0x04   | 0x08   | 0x0C       | 0x10       | 0x14
ForwardAE [1:0]   | 2'b00  | 2'b00  | 2'b00  | 2'b10(MEM) | 2'b10(MEM) | 2'b00
ForwardBE [1:0]   | 2'b00  | 2'b00  | 2'b00  | 2'b00      | 2'b01(WB)  | 2'b00
ALU_ResultE       |   0    |   0    |   10   |    15      |     25     |   ...
ResultW [31:0]    |  ---   |  ---   |  ---   |    ---     |     10     |   15
```

#### 2. Load-Use Hazard Stall Waveform (1 Bubble Injected)
```text
Clock Cycle       | CC5        | CC6        | CC7 (STALL) | CC8        | CC9
------------------+------------+------------+-------------+------------+---------
clk               |  _/~~\_    |  _/~~\_    |  _/~~\_     |  _/~~\_    |  _/~~\_
PC_F [31:0]       | 0x14       | 0x18       | 0x18 (HELD) | 0x1C       | 0x20
Instr_D [31:0]    | lw x4      | addi x5    | addi x5(HLD)| sw x5      | ...
StallF / StallD   |   0        |   0        |      1      |   0        |   0
FlushE (Bubble)   |   0        |   0        |      1      |   0        |   0
ForwardAE [1:0]   | 2'b00      | 2'b00      |    2'b00    | 2'b10(MEM) | 2'b00
ResultW [31:0]    | 25 (x3)    |  ---       |    ---      | 25 (lw x4) | BUBBLE
```

#### 3. Control Hazard Branch Taken Waveform (2 Wrong-Path Flushes)
```text
Clock Cycle       | CC4        | CC5        | CC6 (TAKEN) | CC7 (FLUSHED)| CC8
------------------+------------+------------+-------------+--------------+---------
clk               |  _/~~\_    |  _/~~\_    |  _/~~\_     |  _/~~\_      |  _/~~\_
PC_F [31:0]       | 0x0C       | 0x10       | 0x14        | 0x18(Target) | 0x1C
Instr_D [31:0]    | beq        | addi x3    | addi x4     | NOP(Flushed) | addi x5
FlushD / FlushE   |   0        |   0        |      1      |      0       |   0
PCSrcE            |   0        |   0        |      1      |      0       |   0
ResultW [31:0]    | ...        | ...        | ...         | ...          | 1 (x5)
```

---

## Synthesis & ASIC Implementation

### Standalone Yosys Synthesis

Run logic synthesis to verify cell counts, flip-flops, and area:

```bash
make synth
```

**Synthesis Statistics (Yosys 0.69 / Standard Cell Mapping)**:
- **Total Synthesized Cells**: 9,345
- **Sequential Elements**: 1,632 flip-flops (`$_DFFE_PN0P_`, `$_DFF_PN0_`)
- **Logic Gates**: 2,782 AND, 3,413 NAND, 469 MUX, 224 OR, 106 XNOR, 95 XOR
- **Submodules Synthesized**: 10 hierarchical blocks cleanly mapped

---

## Quick Start Guide

### Make Targets
```bash
make all      # Assemble test codes, simulate, and synthesize core
make sim      # Run automated SystemVerilog test suite
make synth    # Synthesize RV32I core with Yosys
make fpga     # Synthesize Spartan-6 top module
make waves    # Open GTKWave waveform viewer
make clean    # Remove build artifacts
```

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

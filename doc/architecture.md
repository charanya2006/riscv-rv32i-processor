# Architecture Specification: 5-Stage Pipelined RV32I Core

## 1. Complete Datapath & Control Architecture Schematic

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

## 2. Step-by-Step Walkthrough of the Architecture Chart

### Step 1: Instruction Fetch (IF Stage)
1. **PC Mux**: A 2-to-1 multiplexer selects the next instruction address. Under normal sequential execution (`PCSrcE = 0`), it picks `PC + 4`. When a conditional branch is taken or an unconditional jump (`JAL`, `JALR`) is executed (`PCSrcE = 1`), it selects `PCTargetE`.
2. **Program Counter (PC) Register**: Holds the current 32-bit byte address of the instruction being executed. It is updated on every positive clock edge unless frozen by `StallF = 1` during a load-use hazard.
3. **PC Adder (+4)**: Combinational adder that calculates the sequential next instruction address: $\text{PCPlus4F} = \text{PCF} + 4$.
4. **Instruction Memory (IMEM)**: A 4 KB read-only memory (ROM) addressed by `PCF`. It outputs the 32-bit machine instruction `InstrF`.
5. **IF/ID Pipeline Register**: Captures `InstrF`, `PCF`, and `PCPlus4F` on clock edges. It features a synchronous enable (`!StallD`) and synchronous clear (`FlushD`).

---

### Step 2: Instruction Decode (ID Stage)
1. **Instruction Field Extraction**: The 32-bit word `InstrD` is sliced into fields:
   - `Opcode` (`InstrD[6:0]`): Identifies instruction category (R-type, Load, Store, Branch, etc.).
   - `rd` (`InstrD[11:7]`): Destination register index.
   - `funct3` (`InstrD[14:12]`): 3-bit sub-operation identifier.
   - `rs1` (`InstrD[19:15]`): First source register address.
   - `rs2` (`InstrD[24:20]`): Second source register address.
   - `funct7` (`InstrD[31:25]`): 7-bit sub-operation modifier (e.g., distinguishing ADD vs SUB, SRL vs SRA).
2. **Control Unit**: Decodes fields in one combinational pass to produce `ctrl_signals_t`:
   - `reg_write`: Enables register writeback.
   - `result_src`: Selects what value to write to `rd` (ALU result, Memory data, or PC+4).
   - `mem_write` / `mem_read`: Data memory access strobes.
   - `branch`: Conditional branch identifier.
   - `branch_type`: Identifies BEQ, BNE, BLT, BGE, BLTU, BGEU.
   - `jump` / `jalr`: Unconditional jump control flags.
   - `alu_op`: 4-bit encoded ALU mathematical/logical operation.
   - `alu_src_a` / `alu_src_b`: Operand selection multiplexer controls.
3. **Register File (32 x 32-bit)**:
   - Dual asynchronous read ports output `RD1_D` from `rs1` and `RD2_D` from `rs2`.
   - Single synchronous write port commits `ResultW` to `rd_w` on `posedge clk` when `reg_write_w` is asserted.
   - Register `x0` is hardwired to 0 (reads return `32'b0`, writes ignored).
   - **Internal Bypass**: If stage WB writes to register $X$ in the same clock cycle that stage ID reads register $X$, the write data `ResultW` is immediately forwarded to `RD1`/`RD2`.
4. **Immediate Generator (ImmGen)**: Reconstructs 32-bit sign-extended immediates based on the instruction type:
   - **I-Type** (`ADDI`, `LW`): `{{20{inst[31]}}, inst[31:20]}`
   - **S-Type** (`SW`): `{{20{inst[31]}}, inst[31:25], inst[11:7]}`
   - **B-Type** (`BEQ`): `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}`
   - **U-Type** (`LUI`, `AUIPC`): `{inst[31:12], 12'b0}`
   - **J-Type** (`JAL`): `{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}`
5. **ID/EX Pipeline Register**: Captures decoded controls, register values, immediate, PC, and register addresses. Synchronously cleared (`FlushE = 1`) to inject a bubble (NOP) during hazards.

---

### Step 3: Execute (EX Stage)
1. **Forwarding Multiplexers (Mux A & Mux B)**:
   - Selects operand sources dynamically to eliminate RAW data stalls:
     - `2'b00` (`FWD_NONE`): Original register value from ID/EX register.
     - `2'b10` (`FWD_MEM`): Forwarded from EX/MEM register (`ALU_ResultM`) — Distance 1 Hazard.
     - `2'b01` (`FWD_WB`): Forwarded from MEM/WB register (`ResultW`) — Distance 2 Hazard.
2. **ALU Input Multiplexers**:
   - `ALUSrcA Mux`: Chooses between Forwarded Operand A and `PC_E` (for `AUIPC` and `JAL`).
   - `ALUSrcB Mux`: Chooses between Forwarded Operand B and `ImmExt_E` (for immediate operations, loads, and stores).
3. **32-Bit Arithmetic Logic Unit (ALU)**:
   - Performs arithmetic and logic: `ADD`, `SUB`, `SLL` (logical left shift), `SLT` (signed comparison), `SLTU` (unsigned comparison), `XOR`, `SRL` (logical right shift), `SRA` (arithmetic right shift preserving sign), `OR`, `AND`, `PASS_B`.
   - Produces `ALU_ResultE`.
4. **Branch Condition Unit**:
   - Evaluates branch conditions on forwarded inputs: `BEQ` ($A == B$), `BNE` ($A \neq B$), `BLT` (signed $A < B$), `BGE` (signed $A \ge B$), `BLTU` (unsigned $A < B$), `BGEU` (unsigned $A \ge B$).
   - Generates `branch_taken`.
5. **Target Address Generator**:
   - Branch / `JAL` Target: $\text{PCE} + \text{ImmExtE}$
   - `JALR` Target: $(\text{Forwarded\_SrcA} + \text{ImmExtE}) \ \& \sim 1$
   - Generates `PCTargetE` and asserts `PCSrcE = jump || (branch && branch_taken)`.
6. **EX/MEM Pipeline Register**: Captures `ALU_ResultE`, forwarded store data `WriteDataE`, `RD_E`, `RS2_E`, and control signals.

---

### Step 4: Memory Access (MEM Stage)
1. **Store Data Forwarding**: If a store instruction in MEM writes a register that is currently being committed in WB (`RegWriteW && RD_W == RS2_M`), `ForwardMB` forwards `ResultW` directly to the store data path.
2. **Byte Mask & Data Alignment Generator**:
   - Generates byte strobe signals `wmask[3:0]` and shifts bytes into the proper word position based on byte offset `addr[1:0]`:
     - `SB` (Byte): 1 active mask bit (`0001`, `0010`, `0100`, or `1000`).
     - `SH` (Halfword): 2 active mask bits (`0011` or `1100`).
     - `SW` (Word): All 4 mask bits active (`1111`).
3. **Data Memory (DMEM)**: A 4 KB byte-addressable RAM. On memory writes, enabled bytes are committed. On memory reads, the 32-bit word is returned.
4. **Load Data Alignment & Extension**:
   - Slices the required byte or halfword from the 32-bit word based on `addr[1:0]`.
   - Sign-extends (`LB`, `LH`) or zero-extends (`LBU`, `LHU`) into a full 32-bit register value `ReadDataM`.
5. **MEM/WB Pipeline Register**: Captures `ReadDataM`, `ALU_ResultM`, `RD_M`, `PCPlus4M`, and control signals.

---

### Step 5: Writeback (WB Stage)
1. **Result Multiplexer**: Selects the final 32-bit retirement value `ResultW` based on `ResultSrcW`:
   - `RES_ALU`: `ALU_ResultW` (for R-type, I-type math, `LUI`, `AUIPC`).
   - `RES_MEM`: `ReadDataW` (for Loads).
   - `RES_PC4`: `PCPlus4W` (for subroutine call links `JAL`, `JALR`).
2. **Register Commit**: Drives `ResultW` back to the Register File write port, committing to register `RD_W` when `RegWriteW` is high.

---

### Step 6: Hazard Detection & Forwarding Unit (The Pipeline Engine)
The unit continuously samples the pipeline registers and enforces data and control integrity:

1. **RAW Forwarding Logic**:
   - Evaluates source registers in EX against destination registers in MEM and WB:
     - If `RegWriteM && RdM != 0 && RdM == Rs1E` $\rightarrow$ `ForwardAE = 2'b10` (MEM to EX forwarding).
     - Else if `RegWriteW && RdW != 0 && RdW == Rs1E` $\rightarrow$ `ForwardAE = 2'b01` (WB to EX forwarding).
     - Same logic applies to operand B (`ForwardBE`).
2. **Load-Use Hazard Detection & Stalling**:
   - Triggered when:
     $$\text{MemReadE} \land (\text{RdE} \neq 0) \land [(\text{Rs1UsedD} \land \text{RdE} == \text{Rs1D}) \lor (\text{Rs2UsedD} \land \text{RdE} == \text{Rs2D})]$$
   - Actions:
     - `StallF = 1`: Freezes PC register.
     - `StallD = 1`: Freezes IF/ID register (holds decoded instruction).
     - `FlushE = 1`: Clears ID/EX register (inserts 1-cycle execution bubble).
3. **Branch/Jump Control Hazard Flushing**:
   - Triggered when: `PCSrcE == 1'b1` (branch taken or jump resolved in EX).
   - Actions:
     - `FlushD = 1`: Clears IF/ID register (overwrites with NOP `32'h00000013`).
     - `FlushE = 1`: Clears ID/EX register.
     - PC Mux loads `PCTargetE`.
     - Penalty: Exactly 2 clock cycles on taken branches, 0 penalty on not-taken branches.

---

## 3. RV32I Instruction Set Support Table

| Category | Instructions | Description |
|---|---|---|
| **R-Type** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | Register-register arithmetic & logic |
| **I-Type ALU** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | Register-immediate arithmetic & logic |
| **Loads** | `LB`, `LH`, `LW`, `LBU`, `LHU` | Signed/unsigned byte, halfword, word loads |
| **Stores** | `SB`, `SH`, `SW` | Byte, halfword, word memory stores |
| **Branches** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | Conditional PC branching on 6 conditions |
| **Jumps** | `JAL`, `JALR` | Unconditional jump & link to `rd` |
| **Upper Imm** | `LUI`, `AUIPC` | Load / Add Upper Immediate (20 bits) |
| **System** | `ECALL`, `EBREAK`, `FENCE` | Environmental traps and memory barriers |

---

## 4. Hardware Synthesis & Metrics

### Gate-Level Synthesis (Yosys)
- **Cell Count**: 9,345 logic cells
- **Registers / DFFs**: 1,632 flip-flops
- **Submodule Hierarchy**:
  - `decode_stage` (including `register_file`, `imm_gen`, `control_unit`)
  - `execute_stage` (including `alu`, `branch_unit`)
  - `memory_stage`
  - `fetch_stage`
  - `hazard_unit`
  - Pipeline registers (`if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`)

### Spartan-6 FPGA Board Implementation
- **Target Device**: Xilinx Spartan-6 XC6SLX9 / XC6SLX16
- **Internal Core Clock**: 10 MHz (divided from 50 MHz/100 MHz board oscillator)
- **Peripherals Integrated**:
  - 2-Stage button debouncers with 20ms glitch filtering
  - 4-Digit time-multiplexed 7-segment hex display
  - 8-LED diagnostic register/status panel

#==============================================================================
# Makefile for 5-Stage Pipelined RV32I Processor
# Targets:
#   make all     - Assemble test programs, run simulations, and run logic synthesis
#   make asm     - Assemble RISC-V assembly programs into hex machine code
#   make sim     - Compile and run all self-checking SystemVerilog testbenches
#   make synth   - Synthesize RV32I Core with Yosys for ASIC / RTL-to-GDS flow
#   make fpga    - Synthesize Spartan-6 Top Module with Yosys
#   make waves   - View waveform with GTKWave
#   make clean   - Remove simulation binaries and logs
#==============================================================================

PYTHON  = python3
IVERILOG = iverilog
VVP     = vvp
YOSYS   = yosys
SV2V    = sv2v
GTKWAVE = gtkwave

RTL_PKG = rtl/pkg/rv32i_pkg.sv
RTL_CORE = $(wildcard rtl/core/*.sv)
RTL_MEM = $(wildcard rtl/memory/*.sv)
RTL_FPGA = $(wildcard rtl/fpga/*.sv)
TB_SRCS = tb/tb_rv32i_core.sv tb/assertions/rv32i_sva.sv

.PHONY: all asm sim synth fpga waves clean

all: asm sim synth

asm:
	@echo "==> Assembling RISC-V test programs..."
	$(PYTHON) sim/assembler.py tests/asm/basic_tests.s tests/hex/basic_tests.hex
	$(PYTHON) sim/assembler.py tests/asm/hazard_tests.s tests/hex/hazard_tests.hex
	$(PYTHON) sim/assembler.py tests/asm/branch_tests.s tests/hex/branch_tests.hex
	$(PYTHON) sim/assembler.py tests/asm/fibonacci.s tests/hex/fibonacci.hex
	@echo "==> All test programs assembled successfully."

sim: asm
	@echo "==> Running automated verification suite..."
	$(PYTHON) sim/run_sim.py

synth:
	@echo "==> Elaborating SystemVerilog core with sv2v..."
	$(SV2V) -Irtl/pkg -Irtl/core $(RTL_PKG) $(RTL_CORE) > asic/yosys/rv32i_core_elaborated.v
	@echo "==> Running Yosys Logic Synthesis for RV32I Core..."
	$(YOSYS) -p "read_verilog asic/yosys/rv32i_core_elaborated.v; synth -top rv32i_core; stat; write_verilog -noattr asic/yosys/rv32i_core_synth.v"
	@echo "==> Core synthesis complete. Netlist: asic/yosys/rv32i_core_synth.v"

fpga:
	@echo "==> Elaborating Spartan-6 FPGA Top with sv2v..."
	$(SV2V) -Irtl/pkg -Irtl/core -Irtl/memory -Irtl/fpga $(RTL_PKG) $(RTL_CORE) $(RTL_MEM) $(RTL_FPGA) > asic/yosys/spartan6_top_elaborated.v
	@echo "==> Running Yosys Synthesis for Spartan-6 FPGA Top..."
	$(YOSYS) -p "read_verilog asic/yosys/spartan6_top_elaborated.v; synth -top spartan6_top; stat; write_verilog -noattr asic/yosys/spartan6_top_synth.v"
	@echo "==> FPGA synthesis complete. Netlist: asic/yosys/spartan6_top_synth.v"

waves:
	$(GTKWAVE) sim/waves.vcd sim/pipeline_view.gtkw &

clean:
	rm -f sim/sim_rv32i sim/waves.vcd asic/yosys/*_elaborated.v asic/yosys/*_synth.v asic/yosys/*.json
	rm -rf fpga_build/
	@echo "==> Cleaned up all build artifacts."

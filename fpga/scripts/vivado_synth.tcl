#==============================================================================
# File: vivado_synth.tcl
# Description: Automated Vivado Batch Synthesis & Implementation Script
# Target: Xilinx Vivado (FPGA Deployment)
# Run: vivado -mode batch -source fpga/scripts/vivado_synth.tcl
#==============================================================================

# 1. Configuration & Target Part Definition
set part_name "xc7a35tcpg236-1" ;# Basys 3 / Artix-7 (or xc6slx9-2tqg144 for Spartan-6 in ISE)
set output_dir "./fpga_build"

file mkdir $output_dir

# 2. Read SystemVerilog RTL Sources
read_verilog -sv {
    rtl/pkg/rv32i_pkg.sv
    rtl/core/alu.sv
    rtl/core/branch_unit.sv
    rtl/core/register_file.sv
    rtl/core/imm_gen.sv
    rtl/core/control_unit.sv
    rtl/core/hazard_unit.sv
    rtl/core/fetch_stage.sv
    rtl/core/if_id_reg.sv
    rtl/core/decode_stage.sv
    rtl/core/id_ex_reg.sv
    rtl/core/execute_stage.sv
    rtl/core/ex_mem_reg.sv
    rtl/core/memory_stage.sv
    rtl/core/mem_wb_reg.sv
    rtl/core/writeback_stage.sv
    rtl/core/rv32i_core.sv
    rtl/memory/instruction_mem.sv
    rtl/memory/data_mem.sv
    rtl/core/rv32i_top.sv
    rtl/fpga/clk_divider.sv
    rtl/fpga/debouncer.sv
    rtl/fpga/seven_seg_controller.sv
    rtl/fpga/spartan6_top.sv
}

# 3. Read Physical & Timing Constraints
read_xdc fpga/basys3_vivado.xdc

# 4. Run Synthesis
synth_design -top spartan6_top -part $part_name -flatten_hierarchy rebuilt
write_checkpoint -force $output_dir/post_synth.dcp
report_utilization -file $output_dir/post_synth_utilization.rpt
report_timing_summary -file $output_dir/post_synth_timing.rpt

# 5. Run Optimization & Placement
opt_design
place_design
write_checkpoint -force $output_dir/post_place.dcp
report_clock_utilization -file $output_dir/post_place_clock_util.rpt

# 6. Run Routing
route_design
write_checkpoint -force $output_dir/post_route.dcp
report_route_status -file $output_dir/post_route_status.rpt
report_timing_summary -max_paths 10 -file $output_dir/post_route_timing.rpt
report_power -file $output_dir/post_route_power.rpt
report_utilization -file $output_dir/post_route_utilization.rpt

# 7. Generate Bitstream
write_bitstream -force $output_dir/rv32i_spartan6_top.bit

puts "======================================================================"
puts "Vivado FPGA Implementation Completed Successfully!"
puts "Bitstream generated at: $output_dir/rv32i_spartan6_top.bit"
puts "Utilization & Timing reports available in: $output_dir"
puts "======================================================================"

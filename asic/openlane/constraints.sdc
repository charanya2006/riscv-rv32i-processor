#==============================================================================
# File: constraints.sdc
# Description: Synopsys Design Constraints for OpenLane / OpenROAD Flow
# Target: SkyWater 130nm (sky130_fd_sc_hd)
#==============================================================================

# 1. Primary Clock Definition (100 MHz target => 10.0 ns period)
create_clock -name clk_i -period 10.000 [get_ports {clk_i}]

# Clock Uncertainty and Transition
set_clock_uncertainty 0.250 [get_clocks {clk_i}]
set_clock_transition  0.150 [get_clocks {clk_i}]

# 2. Input Delays (assuming 20% of cycle external delay)
set_input_delay  2.000 -clock [get_clocks {clk_i}] [get_ports {rst_ni}]
set_input_delay  2.000 -clock [get_clocks {clk_i}] [get_ports {imem_rdata_i[*]}]
set_input_delay  2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_rdata_i[*]}]

# 3. Output Delays (assuming 20% of cycle external setup)
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {imem_addr_o[*]}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_addr_o[*]}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_wdata_o[*]}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_wmask_o[*]}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_wen_o}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {dmem_ren_o}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {debug_*[*]}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {debug_reg_write_w_o}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {debug_stall_o}]
set_output_delay 2.000 -clock [get_clocks {clk_i}] [get_ports {debug_flush_o}]

# 4. Driving Cell & Load
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [all_inputs]
set_load 0.035 [all_outputs]

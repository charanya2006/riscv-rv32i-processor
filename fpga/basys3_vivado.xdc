#==============================================================================
# File: basys3_vivado.xdc
# Target: Xilinx Vivado (Artix-7 / Spartan-7 / Basys 3)
# Description: Timing and physical pin constraints for RV32I Processor Top
#==============================================================================

# Clock signal (100 MHz oscillator)
set_property PACKAGE_PIN W5 [get_ports board_clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports board_clk_i]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports board_clk_i]

# Push Buttons
set_property PACKAGE_PIN U18 [get_ports btn_rst_ni]
set_property IOSTANDARD LVCMOS33 [get_ports btn_rst_ni]

set_property PACKAGE_PIN T18 [get_ports btn_step_i]
set_property IOSTANDARD LVCMOS33 [get_ports btn_step_i]

# Switches
set_property PACKAGE_PIN V17 [get_ports {sw_disp_sel_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_disp_sel_i[0]}]

set_property PACKAGE_PIN V16 [get_ports {sw_disp_sel_i[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_disp_sel_i[1]}]

set_property PACKAGE_PIN W16 [get_ports sw_step_mode_i]
set_property IOSTANDARD LVCMOS33 [get_ports sw_step_mode_i]

# Diagnostic LEDs
set_property PACKAGE_PIN U16 [get_ports {led_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[0]}]
set_property PACKAGE_PIN E19 [get_ports {led_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[1]}]
set_property PACKAGE_PIN U19 [get_ports {led_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[2]}]
set_property PACKAGE_PIN V19 [get_ports {led_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[3]}]
set_property PACKAGE_PIN W18 [get_ports {led_o[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[4]}]
set_property PACKAGE_PIN U15 [get_ports {led_o[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[5]}]
set_property PACKAGE_PIN U14 [get_ports {led_o[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[6]}]
set_property PACKAGE_PIN V14 [get_ports {led_o[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[7]}]

# Seven Segment Display Cathodes
set_property PACKAGE_PIN W7 [get_ports {seg_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg_o[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg_o[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg_o[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[6]}]

# Seven Segment Display Anodes
set_property PACKAGE_PIN U2 [get_ports {anode_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_o[0]}]
set_property PACKAGE_PIN U4 [get_ports {anode_o[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_o[1]}]
set_property PACKAGE_PIN V4 [get_ports {anode_o[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_o[2]}]
set_property PACKAGE_PIN W4 [get_ports {anode_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode_o[3]}]

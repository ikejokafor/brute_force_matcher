vlib work

vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo_64dsp0/sim/brute_force_matcher_secondary_buffer_fifo_64dsp0.v
vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo_64dsp1/sim/brute_force_matcher_secondary_buffer_fifo_64dsp1.v
vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo/sim/brute_force_matcher_secondary_buffer_fifo.v
vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_match_table_info_bram/sim/brute_force_matcher_match_table_info_bram.v
vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/fifo_74_74_1024_fwft/sim/fifo_74_74_1024_fwft.v
vcom -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_fixed_to_flt/sim/brute_force_matcher_fixed_to_flt.vhd
vcom -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_squareRoot/sim/brute_force_matcher_squareRoot.vhd
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo_64dsp0/brute_force_matcher_secondary_buffer_fifo_64dsp0_sim_netlist.v
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo_64dsp1/brute_force_matcher_secondary_buffer_fifo_64dsp1_sim_netlist.v
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_secondary_buffer_fifo/brute_force_matcher_secondary_buffer_fifo_sim_netlist.v
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_match_table_info_bram/brute_force_matcher_match_table_info_bram_sim_netlist.v
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_squareRoot/brute_force_matcher_squareRoot_sim_netlist.v
#vlog -work work $env(SOC_IT_ROOT)/brute_force_matcher/hardware/ip/xcku115/brute_force_matcher_fixed_to_flt/brute_force_matcher_fixed_to_flt_sim_netlist.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_dispatch_unit.v
vlog -lint -sv +define+VERIFICATION +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_match_table.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_circular_descriptor_buffer.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_secondary_descriptor_buffer.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/address_incrementer.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_controller.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_descriptor_compute_pipeline.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_secondary_buffer_control.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/master_transactor.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_engine.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/master_if_arbiter_nway.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_datapath.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_format_conv.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/xilinx_simple_dual_port_1_clock_ram.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/SRL_bit.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/SRL_bus.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_keyPointEngine.v
vlog -lint -sv +define+SIMULATION -work work +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog/brute_force_matcher_preSubSquareAccum_DSP.v


## Accel Vivado IP Modules
vlog -work work C:/Xilinx/Vivado/2016.4/data//verilog/src/glbl.v


## Verification Modules
vlog -lint -sv -work work +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/ +incdir+$env(SOC_IT_ROOT)/soc_it_bfm/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/Keypoint.sv
vlog -lint -sv -work work +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/ +incdir+$env(SOC_IT_ROOT)/soc_it_bfm/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/MatcherAccelMSG.sv
vlog -lint -sv -work work +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/ +incdir+$env(SOC_IT_ROOT)/soc_it_bfm/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/main.sv
vlog -lint -sv -work work +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/hardware/verilog +incdir+$env(SOC_IT_ROOT)/soc_it_common/hardware/include +incdir+$env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/ +incdir+$env(SOC_IT_ROOT)/soc_it_bfm/hardware/verilog $env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/testbench.sv
vlog -lint -sv $env(SOC_IT_ROOT)/brute_force_matcher/verification/scenario0/clock_gen.v


vsim +notimingchecks -novopt -t 1ns -L work -L soc_it_bfm -L soc_it_capi -L soc_it_common -L secureip -L unisims_ver -L simprims_ver -L unimacro_ver -L unifast_ver -L blk_mem_gen_v8_3_5 -L fifo_generator_v13_1_3 -L fifo_generator_v13_0_5 -L fifo_generator_v12_0_5 -fsmdebug -c +nowarnTSCALE work.glbl work.testbench


do wave.do

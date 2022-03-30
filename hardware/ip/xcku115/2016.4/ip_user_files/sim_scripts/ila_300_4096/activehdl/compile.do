vlib work
vlib activehdl

vlib activehdl/xil_defaultlib
vlib activehdl/xpm

vmap xil_defaultlib activehdl/xil_defaultlib
vmap xpm activehdl/xpm

vlog -work xil_defaultlib -v2k5 -sv "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_base.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_dpdistram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_dprom.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_sdpram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_spram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_sprom.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_tdpram.sv" \

vcom -work xpm -93 \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -v2k5 "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" \
"../../../../ila_300_4096/sim/ila_300_4096.v" \

vlog -work xil_defaultlib "glbl.v"


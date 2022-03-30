vlib work
vlib msim

vlib msim/xil_defaultlib
vlib msim/xpm

vmap xil_defaultlib msim/xil_defaultlib
vmap xpm msim/xpm

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_base.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_dpdistram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_dprom.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_sdpram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_spram.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_sprom.sv" \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_memory/hdl/xpm_memory_tdpram.sv" \

vcom -work xpm -64 -93 \
"/home/software/vivado-2016.1/Vivado/2016.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" "+incdir+../../../../ila_300_4096/ila_v6_1_0/hdl/verilog" "+incdir+../../../../ila_300_4096/ltlib_v1_0_0/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbm_v1_1_2/hdl/verilog" "+incdir+../../../../ila_300_4096/xsdbs_v1_0_2/hdl/verilog" \
"../../../../ila_300_4096/sim/ila_300_4096.v" \

vlog -work xil_defaultlib "glbl.v"


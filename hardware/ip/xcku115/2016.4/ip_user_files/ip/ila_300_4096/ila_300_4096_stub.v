// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.1 (lin64) Build 1538259 Fri Apr  8 15:45:23 MDT 2016
// Date        : Tue Aug 29 18:44:26 2017
// Host        : redrealm.cse.psu.edu running 64-bit Red Hat Enterprise Linux Client release 5.11 (Tikanga)
// Command     : write_verilog -force -mode synth_stub
//               /home/mdl/izo5011/SOC_IT/brute_force_matcher/hardware/ip/xcku115/ila_300_4096/ila_300_4096_stub.v
// Design      : ila_300_4096
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1157-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2016.1" *)
module ila_300_4096(clk, probe0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[299:0]" */;
  input clk;
  input [299:0]probe0;
endmodule

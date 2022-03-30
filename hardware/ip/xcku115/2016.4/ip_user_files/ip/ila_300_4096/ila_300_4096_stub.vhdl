-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.1 (lin64) Build 1538259 Fri Apr  8 15:45:23 MDT 2016
-- Date        : Tue Aug 29 18:44:26 2017
-- Host        : redrealm.cse.psu.edu running 64-bit Red Hat Enterprise Linux Client release 5.11 (Tikanga)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/mdl/izo5011/SOC_IT/brute_force_matcher/hardware/ip/xcku115/ila_300_4096/ila_300_4096_stub.vhdl
-- Design      : ila_300_4096
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx485tffg1157-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_300_4096 is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 299 downto 0 )
  );

end ila_300_4096;

architecture stub of ila_300_4096 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[299:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2016.1";
begin
end;

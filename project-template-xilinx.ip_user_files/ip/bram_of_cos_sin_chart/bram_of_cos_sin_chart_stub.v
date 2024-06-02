// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Sun Jun  2 10:33:14 2024
// Host        : koishi running 64-bit Arch Linux
// Command     : write_verilog -force -mode synth_stub
//               /home/satori/vivado/digital-design-grp-03/project-template-xilinx.srcs/sources_1/ip/bram_of_cos_sin_chart/bram_of_cos_sin_chart_stub.v
// Design      : bram_of_cos_sin_chart
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module bram_of_cos_sin_chart(clka, ena, addra, douta, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,addra[10:0],douta[63:0],clkb,enb,addrb[10:0],doutb[63:0]" */;
  input clka;
  input ena;
  input [10:0]addra;
  output [63:0]douta;
  input clkb;
  input enb;
  input [10:0]addrb;
  output [63:0]doutb;
endmodule

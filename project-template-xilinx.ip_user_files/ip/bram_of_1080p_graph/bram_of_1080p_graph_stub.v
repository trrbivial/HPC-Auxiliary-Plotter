// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Tue May 14 16:20:53 2024
// Host        : koishi running 64-bit Arch Linux
// Command     : write_verilog -force -mode synth_stub
//               /home/satori/vivado/digital-design-grp-03/project-template-xilinx.srcs/sources_1/ip/bram_of_1080p_graph/bram_of_1080p_graph_stub.v
// Design      : bram_of_1080p_graph
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module bram_of_1080p_graph(clka, wea, addra, dina, douta, clkb, web, addrb, dinb, 
  doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[18:0],dina[15:0],douta[15:0],clkb,web[0:0],addrb[18:0],dinb[15:0],doutb[15:0]" */;
  input clka;
  input [0:0]wea;
  input [18:0]addra;
  input [15:0]dina;
  output [15:0]douta;
  input clkb;
  input [0:0]web;
  input [18:0]addrb;
  input [15:0]dinb;
  output [15:0]doutb;
endmodule

// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Mon May 13 13:58:41 2024
// Host        : koishi running 64-bit Arch Linux
// Command     : write_verilog -force -mode synth_stub
//               /home/satori/vivado/digital-design-grp-03/project-template-xilinx.srcs/sources_1/ip/bram_of_1024_complex/bram_of_1024_complex_stub.v
// Design      : bram_of_1024_complex
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module bram_of_1024_complex(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[9:0],dina[63:0],clkb,addrb[9:0],doutb[63:0]" */;
  input clka;
  input [0:0]wea;
  input [9:0]addra;
  input [63:0]dina;
  input clkb;
  input [9:0]addrb;
  output [63:0]doutb;
endmodule

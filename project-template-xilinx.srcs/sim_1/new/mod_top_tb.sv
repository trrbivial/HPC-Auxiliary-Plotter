`timescale 1ns / 1ps

`include "complex.vh"

module mod_top_tb();

    reg clk;
    reg rst;

    initial begin
        //$dumpfile("dump.vcd");
        //$dumpvars(0, mod_top_tb);
        clk = 1'b0;
        rst = 1'b0;

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #500000;
        //$finish;
    end

    always #5 clk = ~clk; // 100MHz

    mod_top dut (
        .clk_100m(clk),
        .btn_clk(1'b0),
        .btn_rst(rst),
        .btn_push(4'b0),
        .dip_sw(16'b0),
        .ps2_keyboard_clk(ps2_keyboard_clk), 
        .ps2_keyboard_data(ps2_keyboard_data),
        .base_ram_data(base_ram_data),
        .base_ram_addr(base_ram_addr),
        .base_ram_be_n(base_ram_be_n),
        .base_ram_ce_n(base_ram_ce_n),
        .base_ram_oe_n(base_ram_oe_n),
        .base_ram_we_n(base_ram_we_n)
    );

endmodule


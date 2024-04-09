`timescale 1ns/1ps
module mod_top_tb();

    reg clock;
    reg reset;

    wire [31:0] base_ram_data; // SRAM 数据
    wire [19:0] base_ram_addr; // SRAM 地址
    wire [3:0] base_ram_be_n; // SRAM 字节使能，低有效。如果不使用字节使能，请保持为0
    wire base_ram_ce_n; // SRAM 片选，低有效
    wire base_ram_oe_n; // SRAM 读使能，低有效
    wire base_ram_we_n; // SRAM 写使能，低有效

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mod_top_tb);
        clock = 1'b0;
        reset = 1'b0;

        #100;
        reset = 1'b1;

        #100;
        reset = 1'b0;

        #50000;
        $finish;
    end

    always #5 clock = ~clock; // 100MHz

    // SRAM 仿真模型
    sram_model sram1 (
        .DataIO(base_ram_data[15:0]),
        .Address(base_ram_addr[19:0]),
        .OE_n(base_ram_oe_n),
        .CE_n(base_ram_ce_n),
        .WE_n(base_ram_we_n),
        .LB_n(base_ram_be_n[0]),
        .UB_n(base_ram_be_n[1])
    );
    sram_model sram2 (
        .DataIO(base_ram_data[31:16]),
        .Address(base_ram_addr[19:0]),
        .OE_n(base_ram_oe_n),
        .CE_n(base_ram_ce_n),
        .WE_n(base_ram_we_n),
        .LB_n(base_ram_be_n[2]),
        .UB_n(base_ram_be_n[3])
    );

    mod_top dut(
        .clk_100m(clock),
        .btn_rst(reset),

        .base_ram_data(base_ram_data),
        .base_ram_addr(base_ram_addr),
        .base_ram_be_n(base_ram_be_n),
        .base_ram_ce_n(base_ram_ce_n),
        .base_ram_oe_n(base_ram_oe_n),
        .base_ram_we_n(base_ram_we_n)
    );

endmodule

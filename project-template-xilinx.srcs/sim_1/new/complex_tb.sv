`timescale 1ns/1ps

`include "complex.vh"

module complex_tb();

    reg clk;
    reg rst;

    logic [31:0] a_tdata;
    logic [31:0] b_tdata;
    logic valid;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, complex_tb);
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        a_tdata <= 32'b1100_0000_1101_0011_0011_0011_0011_0011;
        b_tdata <= 32'b0100_0001_0000_1100_1100_1100_1100_1101;
        valid = 1;

        for (integer i = 0; i < 100; i ++) begin
            #10;
            a_tdata <= a_tdata + 1;
            b_tdata <= b_tdata + 1;
        end

        #50000;
        $finish;
    end

    always #5 clk = ~clk; // 100MHz

    cp_axis a, b, c;
    assign a.meta.r = a_tdata;
    assign a.meta.i = a_tdata;
    assign b.meta.r = b_tdata;
    assign b.meta.i = b_tdata;
    assign a.valid = valid;
    assign b.valid = valid;

    complex_multiplier dut(
        .clk(clk),
        .a(a),
        .b(b),
        .c(c)
    );

endmodule


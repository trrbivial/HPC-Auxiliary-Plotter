`timescale 1ns / 1ps

`include "complex.vh"

module sampling_coefs_tb();

    reg clk;
    reg rst;
    logic valid;
    logic iter_ready;
    sample_mode_axis spm1, spm2;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, sampling_coefs_tb);
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        iter_ready = 1;

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #102;
        valid = 1;

        #6000;
        iter_ready = 0;


        #500000;
        $finish;
    end

    always #5 clk = ~clk; // 100MHz

    assign spm1.valid = valid;
    assign spm1.meta.mode = 1;
    assign spm1.meta.range = ONE_HUNDRED_FL;

    cp_axis t1;
    cp_axis t2;


    sampling_coefs m_sampling_coefs (
        clk & iter_ready,
        rst,
        spm1,
        t1,
        t2
    );
    
    assign spm2.valid = valid;
    assign spm2.meta.mode = 0;
    assign spm2.meta.range = PI;

    cp_axis t3;
    cp_axis t4;
    sampling_coefs m_sampling_coefs_circle (
        clk & iter_ready,
        rst,
        spm2,
        t3,
        t4
    );

endmodule

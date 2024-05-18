`timescale 1ns / 1ps

`include "complex.vh"

module generate_poly_tb();

    reg clk;
    reg rst;
    logic valid;
    logic iter_ready;
    coef coef_t1, coef_t2;

    coef_axis coef_in;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, generate_poly_tb);
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        iter_ready = 1;
        coef_t1 = 0;
        coef_t2 = 0;
        for (int i = 0; i <= MAX_DEG; i = i + 1) begin
            if (i <= 4) begin
                coef_t1.p[i].a[i] = ONE_CP;
            end

            coef_t2.p[i].a[2] = ONE_CP;
            coef_t2.p[i].a[1] = ONE_CP;
            coef_t2.p[i].a[0] = ONE_CP;
        end
        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #102;
        valid = 1;

        #10000;
        iter_ready = 0;


        #500000;
        $finish;
    end

    always #5 clk = ~clk; // 100MHz

    assign coef_in.valid = valid;
    assign coef_in.spm.mode = 1;
    assign coef_in.spm.range = ONE_HUNDRED_FL;
    assign coef_in.t1 = coef_t1;
    assign coef_in.t2 = coef_t2;

    poly_axis poly_out;
    generate_poly m_generate_poly (
        clk,
        rst,
        coef_in,
        iter_ready,
        poly_out
    );



endmodule

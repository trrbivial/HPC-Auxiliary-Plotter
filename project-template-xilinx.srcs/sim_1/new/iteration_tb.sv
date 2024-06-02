`timescale 1ns / 1ps

`include "complex.vh"

module iteration_tb();

    reg clk;
    reg rst;

    logic valid;

    cp_axis screen_offset;
    float_axis screen_scalar;

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        screen_offset = {1'b1, {POS_1_5, NEG_0_5}};
        screen_scalar = {1'b1, TWO_HUNDRED_FL};

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #102;
        valid = 1;

        #500000;
    end

    always #5 clk = ~clk; // 100MHz

    coef_axis coef_in;
    poly_axis poly_in;
    mat_axis mat_in;
    roots_axis roots_out;
    logic iter_in_ready;

    always_comb begin
        coef_in = 0;
        coef_in.valid = 1;
        coef_in.spm.mode = 1;
        coef_in.spm.range = ONE_HUNDRED_FL;
        coef_in.p_t1.a[1] = {32'b0, `neg_fl(ONE_FL)};
        coef_in.p_t1.a[0] = ONE_CP; 
        coef_in.ind_t1 = 0;

        coef_in.p_t2.a[1] = ONE_CP;
        coef_in.p_t2.a[0] = {32'b0, ONE_FL};
        coef_in.ind_t2 = 5;

        coef_in.p_c.a[0] = 0;
        coef_in.p_c.a[1] = 0;
        coef_in.p_c.a[2] = {32'b0, `neg_fl(ONE_FL)};
        coef_in.p_c.a[3] = ONE_CP;
        coef_in.p_c.a[4] = {32'b0, `neg_fl(ONE_FL)};
        coef_in.p_c.a[5] = 0;
        coef_in.p_c.a[6] = ONE_CP;
    end

    generate_poly m_gen_poly (
        .clk(clk),
        .rst(rst),
        .in(coef_in),
        .iter_in_ready(iter_in_ready),

        .out(poly_in)
    );

    poly2mat m_poly2mat (
        .clk(clk),
        .rst(rst),
        .in(poly_in),
        .out(mat_in)
    );

    qr_decomp m_qr_decomp_iter (
        .clk(clk),
        .rst(rst),
        .in(mat_in),

        .out(roots_out),
        .in_ready(iter_in_ready)
    );

    pixels_axis pixels_out;

    roots2pixels m_roots2pixels (
        .clk(clk),
        .rst(rst),
        .in(roots_out),
        .offset(screen_offset),
        .scalar(screen_scalar),

        .out(pixels_out)
    );

endmodule


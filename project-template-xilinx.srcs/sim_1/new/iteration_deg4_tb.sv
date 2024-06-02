`timescale 1ns / 1ps

`include "complex.vh"

module iteration_deg4_tb();

    reg clk;
    reg rst;

    logic valid;

    cp_axis screen_offset;
    float_axis screen_scalar;

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        screen_offset = {1'b1, 64'b0};
        screen_scalar = {1'b1, ONE_THOUSAND_FL};

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #102;
        valid = 1;

        #500000;
    end

    always #5 clk = ~clk; // 100MHz

    coef_axis coef;
    poly_axis poly_in;
    mat_axis mat_in;
    roots_axis roots_out;
    logic iter_in_ready;

    always_comb begin
        coef = 0;
        coef.valid = 1;
        coef.spm.mode = 0;
        coef.spm.range = PI;
        coef.p_t1.a[4] = {32'h3E000000, 32'b0}; // +1.0 / 8
        coef.p_t1.a[2] = {32'h3E000000, 32'b0}; // +1.0 / 8
        coef.p_t1.a[1] = {32'b0, 32'hBE000000}; // -1.0i / 8
        coef.p_t1.a[0] = {32'hBE000000, 32'b0}; // -1.0 / 8
        coef.ind_t1 = 2;

        coef.p_t2.a[4] = {32'h3E000000, 32'b0}; // +1.0 / 8
        coef.p_t2.a[2] = {32'b0, 32'hBE000000}; // -1.0i / 8
        coef.p_t2.a[0] = {32'hBE000000, 32'b0}; // -1.0 / 8
        coef.ind_t2 = 4;

        coef.p_c.a[6] = ONE_CP;
    end

    generate_poly m_gen_poly (
        .clk(clk),
        .rst(rst),
        .in(coef),
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
        .mat_n('d3),

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


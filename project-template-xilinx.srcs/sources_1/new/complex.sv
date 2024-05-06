`timescale 1ns / 1ps

`include "complex.vh"

module complex_multiplier #(
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire cp_axis a,
    input wire cp_axis b,
    output wire cp_axis c
);
    cp ma, mb;
    assign ma = a.meta;
    assign mb = b.meta;

    float_axis c0, c1, c2, c3;
    floating_mul_0 floating_mul_m0 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c0.meta),
        .m_axis_result_tvalid(c0.valid)
    );

    floating_mul_0 floating_mul_m1 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c1.meta),
        .m_axis_result_tvalid(c1.valid)
    );

    floating_mul_0 floating_mul_m2 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c2.meta),
        .m_axis_result_tvalid(c2.valid)
    );

    floating_mul_0 floating_mul_m3 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c3.meta),
        .m_axis_result_tvalid(c3.valid)
    );

    logic sub_valid;
    logic add_valid;

    floating_sub_0 floating_sub_m0 (
        .aclk(clk),
        .s_axis_a_tdata(c0.meta),
        .s_axis_a_tvalid(c0.valid),
        .s_axis_b_tdata(c1.meta),
        .s_axis_b_tvalid(c1.valid),
        .m_axis_result_tdata(c.meta.r),
        .m_axis_result_tvalid(sub_valid)
    );

    floating_add_0 floating_add_m0 (
        .aclk(clk),
        .s_axis_a_tdata(c2.meta),
        .s_axis_a_tvalid(c2.valid),
        .s_axis_b_tdata(c3.meta),
        .s_axis_b_tvalid(c3.valid),
        .m_axis_result_tdata(c.meta.i),
        .m_axis_result_tvalid(add_valid)
    );

    assign c.valid = sub_valid & add_valid;
endmodule

`timescale 1ns / 1ps

`include "complex.vh"

module real2circle # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire float_axis in,
    output wire cp_axis out
);
    float_axis theta;

    floating_to_fixed_32_29_0 fl2fixed_32_29 (
        .aclk(clk),
        .s_axis_a_tdata(in.meta),
        .s_axis_a_tvalid(in.valid),
        .m_axis_result_tdata(theta.meta),
        .m_axis_result_tvalid(theta.valid)
    );
    
    cp_axis c;
    cordic_cos_sin_0 calc_cos_sin (
        .aclk(clk),
        .s_axis_phase_tdata(theta.meta),
        .s_axis_phase_tvalid(theta.valid),
        .m_axis_dout_tdata(c.meta),
        .m_axis_dout_tvalid(c.valid)
    );

    logic vr, vi;

    fixed_32_30_to_floating_0 fixed2fl_32_30_r (
        .aclk(clk),
        .s_axis_a_tdata(c.meta.i),
        .s_axis_a_tvalid(c.valid),
        .m_axis_result_tdata(out.meta.r),
        .m_axis_result_tvalid(vr)
    );
    fixed_32_30_to_floating_0 fixed2fl_32_30_i (
        .aclk(clk),
        .s_axis_a_tdata(c.meta.r),
        .s_axis_a_tvalid(c.valid),
        .m_axis_result_tdata(out.meta.i),
        .m_axis_result_tvalid(vi)
    );

    assign out.valid = vr & vi;


endmodule

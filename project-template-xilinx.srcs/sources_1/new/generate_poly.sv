`timescale 1ns / 1ps

`include "complex.vh"

module generate_poly # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire coef_axis in,
    output wire poly_axis out
);
    cp_axis t1, t2;
    sampling_coefs m_sampleing_coefs (
        clk, rst, 
        {in.valid, in.spm},
        t1, t2
    );

endmodule

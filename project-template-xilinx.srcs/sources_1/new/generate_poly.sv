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
    cp_axis tmp1[MAX_DEG:0], tmp2[MAX_DEG:0], tmp3[MAX_DEG:0];
    sampling_coefs m_sampling_coefs (
        clk, rst, 
        {in.valid, in.spm},
        t1, t2
    );
    genvar i;

    generate 
        for (i = 0; i <= MAX_DEG; i = i + 1) begin
            poly_value poly_value_i_1 (
                clk, rst,
                {in.valid, in.t1.p[i]}, t1, tmp1[i]
            );
            poly_value poly_value_i_2 (
                clk, rst,
                {in.valid, in.t2.p[i]}, t2, tmp2[i]
            );
            complex_adder cp_add_i (
                clk, tmp1[i], tmp2[i], tmp3[i]
            );
            assign out.meta.a[i] = tmp3[i].meta;
        end
    endgenerate

    logic valid;
    always_comb begin
        valid = 1;
        for (int i = 0; i <= MAX_DEG; i = i + 1) begin
            valid &= tmp3[i].valid;
        end
    end
    assign out.valid = valid;


endmodule

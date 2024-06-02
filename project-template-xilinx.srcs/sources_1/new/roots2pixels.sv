`timescale 1ns / 1ps

`include "complex.vh"

module roots2pixels # (
    parameter HALF_HSIZE = VGA_HSIZE >> 1,
    parameter HALF_VSIZE = VGA_VSIZE >> 1
) (
    input wire clk,
    input wire rst,
    input wire roots_axis in,
    input wire cp_axis offset,
    input wire float_axis scalar,

    output wire pixels_axis out
);

    cp_axis tmp1[MAX_DEG - 1:0], tmp2[MAX_DEG - 1:0];
    pixel_axis tmp3[MAX_DEG - 1:0];

    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            complex_suber m_cp_suber_i (clk, {in.valid, in.meta.x[i]}, offset, tmp1[i]);
            complex_mul_float m_cp_mul_fl_i (clk, tmp1[i], scalar, tmp2[i]);
            complex2pixel m_cp_to_pixel_i (clk, tmp2[i], tmp3[i]);
        end
    endgenerate

    pixels_axis out_reg;
    always_comb begin
        out_reg.valid = tmp3[0].valid;
        for (int j = 0; j < MAX_DEG; j = j + 1) begin
            out_reg.valid &= tmp3[j].valid;
            out_reg.meta.p[j].x = tmp3[j].meta.x + HALF_HSIZE - 1;
            out_reg.meta.p[j].y = tmp3[j].meta.y + HALF_VSIZE - 1;
        end
    end


    assign out = out_reg;

endmodule

`timescale 1ns / 1ps

`include "complex.vh"

module poly2mat # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire poly_axis in,
 
    output wire mat_axis out
);
    mat_axis out_reg;
    assign out = out_reg;
    always_comb begin
        out_reg = 0;
        out_reg.valid = in.valid;
        for (int i = 1; i < MAX_N; i = i + 1) begin
            out_reg.meta.r[i].c[i - 1] = ONE_CP;
        end
        for (int i = 0; i < MAX_DEG; i = i + 1) begin
            out_reg.meta.r[0].c[i] = `neg_cp(in.meta.a[MAX_DEG - 1 - i]);
        end
    end
endmodule

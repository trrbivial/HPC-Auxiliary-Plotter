`timescale 1ns / 1ps

`include "complex.vh"

module poly_value # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire poly_axis p,
    input wire cp_axis x,
    output wire cp_axis y
);
    cp_axis s[POLY_X_HOLD_CYCS:0];
    cp_axis tmp[MAX_DEG:0];
    genvar i;

    assign s[0] = x;
    assign tmp[MAX_DEG] = {p.valid, p.meta.a[MAX_DEG]};
    generate
        for (i = 1; i <= POLY_X_HOLD_CYCS; i = i + 1) begin
            always_ff @(posedge clk, posedge rst) begin
                if (rst) begin
                    s[i].valid <= 0;
                end else begin
                    s[i] <= s[i - 1];
                end
            end
        end
    endgenerate

    generate 
        for (i = 1; i <= MAX_DEG; i = i + 1) begin
            complex_ax_plus_b cp_ax_b_i (
                clk, 
                tmp[i],
                s[(MAX_DEG - i) * CP_MUL_ADD_CYCS],
                {p.valid, p.meta.a[i - 1]},
                tmp[i - 1]
            );
        end
    endgenerate

    assign y = tmp[0];
endmodule

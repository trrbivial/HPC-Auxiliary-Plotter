
`timescale 1ns / 1ps

`include "complex.vh"

module qr_decomp # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire mat_axis in,
    output wire qr_axis out
);
    qr_axis s[MAX_N - 1:0];

    mat mat_identity;
    always_comb begin
        for (int i = 0; i < MAX_N; i = i + 1) begin
            mat_identity.r[i] = 0;
            mat_identity.r[i].c[i] = ONE_CP;
        end
    end

    assign s[0].valid = in.valid;
    assign s[0].meta.r = in.meta;
    assign s[0].meta.q = mat_identity;

    genvar i;
    generate 
        for (i = 1; i < MAX_N; i = i + 1) begin
            givens_rotations #(i, i - 1, MAX_N) m_givens_rotations (
                .clk(clk),
                .rst(rst),
                .in(s[i - 1]),
                .out(s[i])
            );
        end
    endgenerate

    assign out = s[MAX_N - 1];
endmodule

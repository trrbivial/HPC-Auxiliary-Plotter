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
    cp_axis tmp1[MAX_DEG:0], tmp2[MAX_DEG:0], tmp3[MAX_DEG:0], tmp4[MAX_DEG:0], tmp5[MAX_DEG:0];
    logic [DATA_WIDTH - 1:0] offset;
    sampling_coefs m_sampling_coefs (
        clk, rst, 
        {in.valid, in.spm},
        t1, t2
    );
    always_comb begin
        offset = 0;
        offset[31] = 1'b1;
        for (int i = MAX_DEG; i >= 0; i = i - 1) begin
            if (tmp3[i].meta != 0) begin
                offset = MAX_DEG - i;
                break;
            end
        end
    end
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

        end
        assign tmp4[MAX_DEG] = 
            offset[31] ? {1'b1, ONE_CP} :
            tmp3[i - offset];
        assign tmp5[MAX_DEG] = {1'b1, ONE_CP};
    endgenerate

    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign tmp4[i] = 
                (offset[31] | (i - offset < 0)) ? {1'b1, 64'b0} :
                tmp3[i - offset];

            complex_diver cp_div_i (
                clk, tmp4[i], tmp4[MAX_DEG], tmp5[i]
            );
        end
    endgenerate

    logic valid;
    always_comb begin
        valid = 1;
        for (int i = 0; i <= MAX_DEG; i = i + 1) begin
            valid &= tmp5[i].valid;
        end
    end
    assign out.valid = valid;
    generate 
        for (i = 0; i <= MAX_DEG; i = i + 1) begin
            assign out.meta.a[i] = tmp5[i];
        end
    endgenerate


endmodule

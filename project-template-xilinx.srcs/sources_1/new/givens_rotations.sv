`timescale 1ns / 1ps

`include "complex.vh"

module givens_rotations # (
    parameter ROW_ID = 1,
    parameter COL_ID = 0,
    parameter MAX_N = MAX_DEP
) (
    input wire clk,
    input wire rst,
    input wire qr_axis in,
    output wire qr_axis out
);
    qr_axis s[CALC_GIVENS_ROTATIONS_CYCS:0];
    
    assign s[0] = in;


    // c0 = a.r ^ 2, c1 = a.i ^ 2
    float_axis c0, c1;
    floating_mul_0 a_r_square (
        clk, 
        s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r, 
        s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r, 
        c0.valid, c0.meta.v
    );
    floating_mul_0 a_i_square (
        clk, 
        s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i,  
        s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i, 
        c1.valid, c1.meta.v
    );

    // c2 = c0 + c1 = |a| ^ 2
    float_axis c2;
    floating_add_0 add_r_i (
        clk,
        c0.valid, c0.meta.v,
        c1.valid, c1.meta.v,
        c2.valid, c2.meta.v
    );

    // c3 = c2 + 1 = |a| ^ 2 + 1
    float_axis c3;
    floating_add_0 add_1 (
        clk,
        c2.valid, c2.meta.v, 
        ONE_FL, 1,
        c3.valid, c3.meta.v
    );

    // s = 1 / sqrt(|a| ^ 2 + 1)
    float_axis coef_s;
    floating_reciprocal_sqrt_0 reciprocal_sqrt_c3 (
        clk,
        c3.valid, c3.meta.v,
        coef_s.valid, coef_s.meta.v
    );

    // c = conj(a) / sqrt(|a| ^ 2 + 1) = conj(a) * s
    float_axis coef_c_r, coef_c_i;
    floating_mul_0 mul_conj_a_r_with_coef_s (
        clk,
        s[CALC_GIVENS_COEF_S_CYCS].valid, s[CALC_GIVENS_COEF_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID].r, 
        coef_s.valid, coef_s.meta.v,
        coef_c_r.valid, coef_c_r.meta.v
    );
    floating_mul_0 mul_conj_a_i_with_coef_s (
        clk,
        s[CALC_GIVENS_COEF_S_CYCS].valid, `neg_fl(s[CALC_GIVENS_COEF_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID].i),
        coef_s.valid, coef_s.meta.v,
        coef_c_i.valid, coef_c_i.meta.v
    );

    // c, s from float to complex
    cp_axis coef_cp_c, coef_cp_s;
    assign coef_cp_c.meta = {coef_c_r.meta.v, coef_c_i.meta.v};
    assign coef_cp_c.valid = coef_c_r.valid & coef_c_i.valid;
    assign coef_cp_s.meta = {coef_s.meta.v, 32'b0};
    assign coef_cp_s.valid = coef_s.valid;

    cp_axis tmp1[MAX_N - (COL_ID + 1) - 1:0];
    cp_axis tmp2[MAX_N - (COL_ID + 1) - 1:0];
    cp_axis tmp3, tmp4, tmp5;
    genvar k;
    generate
        for (k = COL_ID + 1; k < MAX_N; k = k + 1) begin
            complex_multiplier cp_mul_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                coef_cp_c,
                tmp1[k - (COL_ID + 1)]);

            complex_multiplier cp_mul_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                {coef_cp_s.valid, {`neg_fl(coef_cp_s.meta.r), coef_cp_s.meta.i}},
                tmp2[k - (COL_ID + 1)]);

        end
    endgenerate

    complex_multiplier cp_mul_3 (
        clk,
        {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID]},
        coef_cp_c,
        tmp3
    );

    complex_multiplier cp_mul_4 (
        clk,
        {1, ONE_CP},
        coef_cp_s,
        tmp4
    );

    complex_adder cp_add_0 (
        clk,
        tmp3,
        tmp4,
        tmp5
    );


    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_ROTATIONS_CYCS; i = i + 1) begin
            case (i)
                CALC_GIVENS_COEF_MUL_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                        for (int j = COL_ID + 1; j < MAX_N; j = j + 1) begin
                            s[i].meta.r.r[ROW_ID - 1].c[j] <= tmp1[j - (COL_ID + 1)].meta;
                            s[i].meta.r.r[ROW_ID].c[j] <= tmp2[j - (COL_ID + 1)].meta;
                        end
                    end
                end
                CALC_GIVENS_COEF_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                        s[i].meta.r.r[ROW_ID - 1].c[COL_ID] <= tmp5.meta;
                        s[i].meta.r.r[ROW_ID].c[COL_ID] <= 0;
                    end
                end
                default: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                    end
                end
            endcase
        end
    endgenerate

    assign out = s[CALC_GIVENS_ROTATIONS_CYCS];
endmodule

`timescale 1ns / 1ps

`include "complex.vh"

module givens_rotations # (
    parameter ROW_ID = 1,
    parameter COL_ID = 0,
    parameter MAX_N = MAX_DEP,
) (
    input wire clk,
    input wire rst,
    input wire qr_axis in,
    output wire qr_axis out
);
    qr_axis s[CALC_GIVENS_COEF_CYCS - 1:0];

    mat mat_identity;
    always_comb begin
        for (int i = 0; i < MAX_N; i = i + 1) begin
            mat_identity.r[i] = 0;
            mat_identity.r[i].c[i] = ONE_CP;
        end
    end
    
    assign s[0] = in;

    genvar i;
    generate begin
        for (i = 1; i < CALC_GIVENS_COEF_CYCS; i = i + 1) begin
            s[i] <= s[i - 1];
        end
    end

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

    float_axis c2;
    floating_add_0 add_r_i (
        clk,
        c0.valid, c0.meta.v,
        c1.valid, c1.meta.v,
        c2.valid, c2.meta.v
    );

    float_axis c3;
    floating_add_0 add_1 (
        clk,
        c2.valid, c2.meta.v, 
        ONE_FL, 1,
        c3.valid, c3.meta.v
    );

    float_axis coef_s;
    floating_reciprocal_sqrt_0 reciprocal_sqrt_c3 (
        clk,
        c3.valid, c3.meta.v,
        coef_s.valid, coef_s.meta.v
    );

    float_axis coef_c_r, coef_c_i;
    floating_mul_0 mul_conj_a_r_with_coef_s (
        clk,
        s[START_CALC_GIVENS_COEF_C_CYCS - 1].valid, s[START_CALC_GIVENS_COEF_C_CYCS - 1].meta.r.r[ROW_ID - 1].c[COL_ID].r, 
        coef_s.valid, coef_s.meta.v,
        coef_c_r.valid, coef_c_r.meta.v
    );
    floating_mul_0 mul_conj_a_i_with_coef_s (
        clk,
        s[START_CALC_GIVENS_COEF_C_CYCS - 1].valid, `neg_fl(s[START_CALC_GIVENS_COEF_C_CYCS - 1].meta.r.r[ROW_ID - 1].c[COL_ID].i),
        coef_s.valid, coef_s.meta.v,
        coef_c_i.valid, coef_c_i.meta.v
    );

    cp_axis coef_cp_c, coef_cp_s;
    assign coef_cp_c.meta = {coef_c_r.meta.v, coef_c_i.meta.v};
    assign coef_cp_c.valid = coef_c_r.valid & coef_c_i.valid;
    assign coef_cp_s.meta = {coef_s.meta.v, 32'b0};
    assign coef_cp_s.valid = coef_s.valid;



    




endmodule

`timescale 1ns / 1ps

`include "complex.vh"

module givens_rotations # (
    parameter ROW_ID = 1,
    parameter COL_ID = 0,
    parameter MAX_N = MAX_DEG
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
        .aclk(clk), 
        .s_axis_a_tvalid(s[0].valid),
        .s_axis_a_tdata(s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r),
        .s_axis_b_tvalid(s[0].valid),
        .s_axis_b_tdata(s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r),
        .m_axis_result_tvalid(c0.valid),
        .m_axis_result_tdata(c0.meta.v)
    );
    floating_mul_0 a_i_square (
        .aclk(clk), 
        .s_axis_a_tvalid(s[0].valid),
        .s_axis_a_tdata(s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i),
        .s_axis_b_tvalid(s[0].valid),
        .s_axis_b_tdata(s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i),
        .m_axis_result_tvalid(c1.valid),
        .m_axis_result_tdata(c1.meta.v)
    );

    // c2 = c0 + c1 = |a| ^ 2
    float_axis c2;
    floating_add_0 add_r_i (
        .aclk(clk), 
        .s_axis_a_tvalid(c0.valid),
        .s_axis_a_tdata(c0.meta.v),
        .s_axis_b_tvalid(c1.valid),
        .s_axis_b_tdata(c1.meta.v),
        .m_axis_result_tvalid(c2.valid),
        .m_axis_result_tdata(c2.meta.v)
    );

    // c3 = c2 + 1 = |a| ^ 2 + 1
    float_axis c3;
    floating_add_0 add_1 (
        .aclk(clk), 
        .s_axis_a_tvalid(c2.valid),
        .s_axis_a_tdata(c2.meta.v),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(ONE_FL),
        .m_axis_result_tvalid(c3.valid),
        .m_axis_result_tdata(c3.meta.v)
    );

    // s = 1 / sqrt(|a| ^ 2 + 1)
    float_axis coef_s;
    floating_reciprocal_sqrt_0 reciprocal_sqrt_c3 (
        .aclk(clk), 
        .s_axis_a_tvalid(c3.valid),
        .s_axis_a_tdata(c3.meta.v),
        .m_axis_result_tvalid(coef_s.valid),
        .m_axis_result_tdata(coef_s.meta.v)
    );

    // c = conj(a) / sqrt(|a| ^ 2 + 1) = conj(a) * s
    float_axis coef_c_r, coef_c_i;
    floating_mul_0 mul_conj_a_r_with_coef_s (
        .aclk(clk), 
        .s_axis_a_tvalid(s[CALC_GIVENS_COEF_S_CYCS].valid),
        .s_axis_a_tdata(s[CALC_GIVENS_COEF_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID].r),
        .s_axis_b_tvalid(coef_s.valid),
        .s_axis_b_tdata(coef_s.meta.v),
        .m_axis_result_tvalid(coef_c_r.valid),
        .m_axis_result_tdata(coef_c_r.meta.v)
    );
    floating_mul_0 mul_conj_a_i_with_coef_s (
        .aclk(clk), 
        .s_axis_a_tvalid(s[CALC_GIVENS_COEF_S_CYCS].valid),
        .s_axis_a_tdata(`neg_fl(s[CALC_GIVENS_COEF_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID].i)),
        .s_axis_b_tvalid(coef_s.valid),
        .s_axis_b_tdata(coef_s.meta.v),
        .m_axis_result_tvalid(coef_c_i.valid),
        .m_axis_result_tdata(coef_c_i.meta.v)
    );

    // c, s from float to complex
    cp_axis coef_cp_c, coef_cp_s;
    assign coef_cp_c.meta = {coef_c_r.meta.v, coef_c_i.meta.v};
    assign coef_cp_c.valid = coef_c_r.valid & coef_c_i.valid;
    assign coef_cp_s.meta = {coef_s.meta.v, 32'b0};
    assign coef_cp_s.valid = coef_s.valid;

    cp_axis tmp1[MAX_N - (COL_ID + 1) - 1:0];
    cp_axis tmp2[MAX_N - (COL_ID + 1) - 1:0];
    cp_axis tmp3;
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

    complex_mul_adder cp_mul_add_0 (
        clk,
        {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID]},
        coef_cp_c,
        {1'b1, ONE_CP},
        coef_cp_s,
        tmp3
    );

    cp_axis tmp4[ROW_ID - 1:0];
    cp_axis tmp5[ROW_ID - 1:0];
    generate 
        for (k = 0; k < ROW_ID; k = k + 1) begin
            complex_multiplier cp_mul_4 (
                clk, 
                {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.q.r[k].c[ROW_ID - 1]},
                coef_cp_c,
                tmp4[k]);

            complex_multiplier cp_mul_5 (
                clk, 
                {s[CALC_GIVENS_COEF_C_CYCS].valid, s[CALC_GIVENS_COEF_C_CYCS].meta.q.r[k].c[ROW_ID - 1]},
                {coef_cp_s.valid, {`neg_fl(coef_cp_s.meta.r), coef_cp_s.meta.i}},
                tmp5[k]);

        end
    endgenerate


    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_ROTATIONS_CYCS; i = i + 1) begin
            case (i)
                CALC_GIVENS_COEF_C_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                        s[i].meta.q.r[ROW_ID].c[ROW_ID - 1] <= coef_cp_s.meta;
                        s[i].meta.q.r[ROW_ID].c[ROW_ID] <= `conj(coef_cp_c.meta);
                    end
                end
                CALC_GIVENS_COEF_MUL_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                        for (int j = COL_ID + 1; j < MAX_N; j = j + 1) begin
                            s[i].meta.r.r[ROW_ID - 1].c[j] <= tmp1[j - (COL_ID + 1)].meta;
                            s[i].meta.r.r[ROW_ID].c[j] <= tmp2[j - (COL_ID + 1)].meta;
                        end
                        for (int j = 0; j < ROW_ID; j = j + 1) begin
                            s[i].meta.q.r[j].c[ROW_ID - 1] <= tmp4[j].meta;
                            s[i].meta.q.r[j].c[ROW_ID] <= tmp5[j].meta;
                        end
                    end
                end
                CALC_GIVENS_COEF_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        s[i] <= s[i - 1];
                        s[i].meta.r.r[ROW_ID - 1].c[COL_ID] <= tmp3.meta;
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

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


    // c0 = |a| ^ 2, c1 = |b| ^ 2
    float_axis c0, c1;
    floating_mul_adder fl_mul_add_0 (
        clk,
        {s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r},
        {s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].r},
        {s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i},
        {s[0].valid, s[0].meta.r.r[ROW_ID - 1].c[COL_ID].i},
        c0
    );
    floating_mul_adder fl_mul_add_1 (
        clk,
        {s[0].valid, s[0].meta.r.r[ROW_ID].c[COL_ID].r},
        {s[0].valid, s[0].meta.r.r[ROW_ID].c[COL_ID].r},
        {s[0].valid, s[0].meta.r.r[ROW_ID].c[COL_ID].i},
        {s[0].valid, s[0].meta.r.r[ROW_ID].c[COL_ID].i},
        c1
    );

    // c2 = c0 + c1 = |a| ^ 2 + |b| ^ 2
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

    // c3 = 1 / sqrt(|a| ^ 2 + |b| ^ 2)
    float_axis c3;
    floating_reciprocal_sqrt_0 reciprocal_sqrt_c3 (
        .aclk(clk), 
        .s_axis_a_tvalid(c2.valid),
        .s_axis_a_tdata(c2.meta.v),
        .m_axis_result_tvalid(c3.valid),
        .m_axis_result_tdata(c3.meta.v)
    );

    // c = conj(a) / sqrt(|a| ^ 2 + |b| ^ 2)
    // s = b / sqrt(|a| ^ 2 + |b| ^ 2)
    cp_axis coef_c, coef_s;
    complex_mul_float calc_c (
        clk,
        {s[CALC_GIVENS_C3_CYCS].valid, `conj(s[CALC_GIVENS_C3_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID])},
        c3,
        coef_c
    );
    complex_mul_float calc_s (
        clk,
        {s[CALC_GIVENS_C3_CYCS].valid, s[CALC_GIVENS_C3_CYCS].meta.r.r[ROW_ID].c[COL_ID]},
        c3,
        coef_s
    );
    cp_axis coef_conj_c, coef_neg_conj_s;
    assign coef_conj_c = {coef_c.valid, `conj(coef_c.meta)};
    assign coef_neg_conj_s = {coef_s.valid, {`neg_fl(coef_s.meta.r), coef_s.meta.i}};

    // [       c,       s]  [conj(c),   -s]
    // [-conj(s), conj(c)]  [conj(s),    c]
    // R <- G * R
    // Q <- Q * Hermite(G)
    cp_axis tmp1[MAX_N - COL_ID - 1:0];
    cp_axis tmp2[MAX_N - COL_ID - 1:0];

    complex_mul_adder cp_mul_add_1 (
        clk, 
        {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID]},
        coef_c,
        {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[COL_ID]},
        coef_s,
        tmp1[0]
    );
    assign tmp2[0] = {1'b1, 64'b0};

    genvar k;
    generate
        for (k = COL_ID + 1; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[k]},
                coef_s,
                tmp1[k - COL_ID]
            );
            complex_mul_adder cp_mul_add_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                coef_neg_conj_s,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[k]},
                coef_conj_c,
                tmp2[k - COL_ID]
            );
        end
    endgenerate

    cp_axis tmp3[ROW_ID - 1:0];
    cp_axis tmp4[ROW_ID - 1:0];
    generate 
        for (k = 0; k < ROW_ID; k = k + 1) begin
            complex_multiplier cp_mul_4 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.q.r[k].c[ROW_ID - 1]},
                {coef_c.valid, `conj(coef_c.meta)},
                tmp3[k]);

            complex_multiplier cp_mul_5 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.q.r[k].c[ROW_ID - 1]},
                {coef_s.valid, `neg_cp(coef_s.meta)},
                tmp4[k]);

        end
    endgenerate


    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_ROTATIONS_CYCS; i = i + 1) begin
            case (i)
                CALC_GIVENS_COEF_C_S_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            s[i].meta.q.r[ROW_ID].c[ROW_ID - 1] <= `conj(coef_s.meta);
                            s[i].meta.q.r[ROW_ID].c[ROW_ID] <= coef_c.meta;
                        end
                    end
                end
                CALC_GIVENS_COEF_MUL_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = 0; j < ROW_ID; j = j + 1) begin
                                s[i].meta.q.r[j].c[ROW_ID - 1] <= tmp3[j].meta;
                                s[i].meta.q.r[j].c[ROW_ID] <= tmp4[j].meta;
                            end
                        end
                    end
                end
                CALC_GIVENS_COEF_MUL_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = COL_ID; j < MAX_N; j = j + 1) begin
                                s[i].meta.r.r[ROW_ID - 1].c[j] <= tmp1[j - COL_ID].meta;
                                s[i].meta.r.r[ROW_ID].c[j] <= tmp2[j - COL_ID].meta;
                            end
                        end
                    end
                end
                default: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                        end
                    end
                end
            endcase
        end
    endgenerate

    assign out = s[CALC_GIVENS_ROTATIONS_CYCS];
endmodule

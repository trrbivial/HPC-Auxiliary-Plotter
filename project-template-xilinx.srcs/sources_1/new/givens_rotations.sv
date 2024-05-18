`timescale 1ns / 1ps

`include "complex.vh"

module givens_rotations # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire qr_axis in,
    output wire qr_axis out
);
    qr_axis s[CALC_GIVENS_COEF_C_S_CYCS + 1:0];
    assign s[0] = in;

    logic [2:0] col_id; 
    logic [2:0] row_id;
    assign col_id = in.meta.col_id;
    assign row_id = in.meta.row_id;
    

    // c0 = |a| ^ 2, c1 = |b| ^ 2
    float_axis c0, c1;
    floating_mul_adder fl_mul_add_0 (
        clk,
        {s[0].valid, s[0].meta.r.r[col_id].c[col_id].r},
        {s[0].valid, s[0].meta.r.r[col_id].c[col_id].r},
        {s[0].valid, s[0].meta.r.r[col_id].c[col_id].i},
        {s[0].valid, s[0].meta.r.r[col_id].c[col_id].i},
        c0
    );
    floating_mul_adder fl_mul_add_1 (
        clk,
        {s[0].valid, s[0].meta.r.r[row_id].c[col_id].r},
        {s[0].valid, s[0].meta.r.r[row_id].c[col_id].r},
        {s[0].valid, s[0].meta.r.r[row_id].c[col_id].i},
        {s[0].valid, s[0].meta.r.r[row_id].c[col_id].i},
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
    // s = conj(b) / sqrt(|a| ^ 2 + |b| ^ 2)
    cp_axis coef_c, coef_s;

/*
    cp_axis coef_c_tmp[CP_MUL_ADD_CYCS + 1:0];
    cp_axis coef_s_tmp[CP_MUL_ADD_CYCS + 1:0];

    assign coef_c_tmp[0] = coef_c;
    assign coef_s_tmp[0] = coef_s;

    genvar k;
    generate 
        for (k = 1; k <= CP_MUL_ADD_CYCS + 1; k = k + 1) begin
            always_ff @(posedge clk, posedge rst) begin
                if (rst) begin
                    coef_c_tmp[k].valid <= 0;
                    coef_s_tmp[k].valid <= 0;
                end else begin
                    coef_c_tmp[k] <= coef_c_tmp[k - 1];
                    coef_s_tmp[k] <= coef_s_tmp[k - 1];
                end
            end
        end
    endgenerate
*/
    logic [2:0] col_id_c3;
    logic [2:0] row_id_c3;
    assign col_id_c3 = s[CALC_GIVENS_C3_CYCS].meta.col_id;
    assign row_id_c3 = s[CALC_GIVENS_C3_CYCS].meta.row_id;

    complex_mul_float calc_c (
        clk,
        {s[CALC_GIVENS_C3_CYCS].valid, `conj(s[CALC_GIVENS_C3_CYCS].meta.r.r[col_id_c3].c[col_id_c3])},
        c3,
        coef_c
    );
    complex_mul_float calc_s (
        clk,
        {s[CALC_GIVENS_C3_CYCS].valid, `conj(s[CALC_GIVENS_C3_CYCS].meta.r.r[row_id_c3].c[col_id_c3])},
        c3,
        coef_s
    );

/*
    cp_axis coef_conj_c, coef_neg_conj_s;
    assign coef_conj_c = {coef_c.valid, `conj(coef_c.meta)};
    assign coef_neg_conj_s = {coef_s.valid, {`neg_fl(coef_s.meta.r), coef_s.meta.i}};
*/

    // [       c,       s]  [conj(c),   -s]
    // [-conj(s), conj(c)]  [conj(s),    c]
    // R <- G * R
    // Q <- Q * Hermite(G)
    // A <- G * A * Hermite(G)

/*
    cp_axis tmp1_r[MAX_N - 1:0], tmp1_a[MAX_N - 1:0];
    cp_axis tmp2_r[MAX_N - 1:0], tmp2_a[MAX_N - 1:0];
    generate
        // k = col_id + 1
        for (k = 0; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[col_id].c[k]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[row_id].c[k]},
                coef_s,
                tmp1_r[k]
            );
            complex_mul_adder cp_mul_add_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[col_id].c[k]},
                coef_neg_conj_s,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[row_id].c[k]},
                coef_conj_c,
                tmp2_r[k]
            );
        end
    endgenerate

    generate 
        for (k = 0; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[col_id].c[k]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[row_id].c[k]},
                coef_s,
                tmp1_a[k]
            );
            complex_mul_adder cp_mul_add_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[col_id].c[k]},
                coef_neg_conj_s,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[row_id].c[k]},
                coef_conj_c,
                tmp2_a[k]
            );
        end
    endgenerate

    cp_axis tmp3_a[MAX_N - 1:0];
    cp_axis tmp4_a[MAX_N - 1:0];
    generate 
        for (k = 0; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_3 (
                clk, 
                {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[col_id]},
                {coef_c_tmp[CP_MUL_ADD_CYCS + 1].valid, `conj(coef_c_tmp[CP_MUL_ADD_CYCS + 1].meta)},
                {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[row_id]},
                {coef_s_tmp[CP_MUL_ADD_CYCS + 1].valid, `conj(coef_s_tmp[CP_MUL_ADD_CYCS + 1].meta)},
                tmp3_a[k]
            );

            complex_mul_adder cp_mul_add_4 (
                clk, 
                {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[col_id]},
                {coef_s_tmp[CP_MUL_ADD_CYCS + 1].valid, `neg_cp(coef_s_tmp[CP_MUL_ADD_CYCS + 1].meta)},
                {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[row_id]},
                {coef_c_tmp[CP_MUL_ADD_CYCS + 1].valid, coef_c_tmp[CP_MUL_ADD_CYCS + 1].meta},
                tmp4_a[k]
            );
        end
    endgenerate

*/

    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_COEF_C_S_CYCS + 1; i = i + 1) begin
            case (i)
                /*
                CALC_GIVENS_COEF_MUL_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = 0; j < MAX_N; j = j + 1) begin
                                s[i].meta.r.r[col_id].c[j] <= tmp1_r[j].meta;
                                s[i].meta.r.r[row_id].c[j] <= tmp2_r[j].meta;
                                s[i].meta.a.r[col_id].c[j] <= tmp1_a[j].meta;
                                s[i].meta.a.r[row_id].c[j] <= tmp2_a[j].meta;
                            end
                        end
                    end
                end
                CALC_GIVENS_SECOND_COEF_MUL_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = 0; j < MAX_N; j = j + 1) begin
                                s[i].meta.a.r[j].c[col_id] <= tmp3_a[j].meta;
                                s[i].meta.a.r[j].c[row_id] <= tmp4_a[j].meta;
                            end
                        end
                    end
                end
                */
                CALC_GIVENS_COEF_C_S_CYCS + 1: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            s[i].valid <= s[i - 1].valid & coef_c.valid & coef_s.valid;
                            if (~s[i - 1].meta.dir) begin
                                s[i].meta.c[s[i - 1].meta.col_id] <= coef_c.meta;
                                s[i].meta.s[s[i - 1].meta.col_id] <= coef_s.meta;
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

    assign out = s[CALC_GIVENS_COEF_C_S_CYCS + 1];

endmodule

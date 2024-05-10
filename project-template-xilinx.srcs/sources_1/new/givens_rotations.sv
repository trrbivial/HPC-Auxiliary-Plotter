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
    cp_axis coef_c_tmp[CP_MUL_ADD_CYCS:0];
    cp_axis coef_s_tmp[CP_MUL_ADD_CYCS:0];

    assign coef_c_tmp[0] = coef_c;
    assign coef_s_tmp[0] = coef_s;

    genvar k;
    generate 
        for (k = 1; k <= CP_MUL_ADD_CYCS; k = k + 1) begin
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
    // A <- G * A * Hermite(G)
    cp_axis tmp1_r[MAX_N - COL_ID - 1:0], tmp1_a[MAX_N - COL_ID - 1:0];
    cp_axis tmp2_r[MAX_N - COL_ID - 1:0], tmp2_a[MAX_N - COL_ID - 1:0];

    complex_mul_adder cp_mul_add_1 (
        clk, 
        {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[COL_ID]},
        coef_c,
        {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[COL_ID]},
        coef_s,
        tmp1_r[0]
    );
    assign tmp2_r[0] = {1'b1, 64'b0};

    generate
        for (k = COL_ID + 1; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[k]},
                coef_s,
                tmp1_r[k - COL_ID]
            );
            complex_mul_adder cp_mul_add_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID - 1].c[k]},
                coef_neg_conj_s,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.r.r[ROW_ID].c[k]},
                coef_conj_c,
                tmp2_r[k - COL_ID]
            );
        end
    endgenerate

    generate 
        for (k = COL_ID; k < MAX_N; k = k + 1) begin
            complex_mul_adder cp_mul_add_1 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID - 1].c[k]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID].c[k]},
                coef_s,
                tmp1_a[k - COL_ID]
            );
            complex_mul_adder cp_mul_add_2 (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID - 1].c[k]},
                coef_neg_conj_s,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID].c[k]},
                coef_conj_c,
                tmp2_a[k - COL_ID]
            );
        end
    endgenerate

    cp_axis pre_diag;
    generate 
        if (COL_ID > 0) begin
            complex_mul_adder cp_mul_add_pre (
                clk, 
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID - 1].c[COL_ID - 1]},
                coef_c,
                {s[CALC_GIVENS_COEF_C_S_CYCS].valid, s[CALC_GIVENS_COEF_C_S_CYCS].meta.a.r[ROW_ID].c[COL_ID - 1]},
                coef_s,
                pre_diag
            );
        end
    endgenerate



    cp_axis tmp3_a[ROW_ID + 1:0];
    cp_axis tmp4_a[ROW_ID + 1:0];
    generate 
        for (k = 0; k <= ROW_ID + 1; k = k + 1) begin
            if (k < MAX_N) begin
                complex_mul_adder cp_mul_add_3 (
                    clk, 
                    {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[COL_ID]},
                    {coef_c_tmp[CP_MUL_ADD_CYCS].valid, `conj(coef_c_tmp[CP_MUL_ADD_CYCS].meta)},
                    {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[COL_ID + 1]},
                    {coef_s_tmp[CP_MUL_ADD_CYCS].valid, `conj(coef_s_tmp[CP_MUL_ADD_CYCS].meta)},
                    tmp3_a[k]
                );

                complex_mul_adder cp_mul_add_4 (
                    clk, 
                    {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[COL_ID]},
                    {coef_s_tmp[CP_MUL_ADD_CYCS].valid, `neg_cp(coef_s_tmp[CP_MUL_ADD_CYCS].meta)},
                    {s[CALC_GIVENS_COEF_MUL_ADD_CYCS].valid, s[CALC_GIVENS_COEF_MUL_ADD_CYCS].meta.a.r[k].c[COL_ID + 1]},
                    {coef_c_tmp[CP_MUL_ADD_CYCS].valid, coef_c_tmp[CP_MUL_ADD_CYCS].meta},
                    tmp4_a[k]
                );
            end
        end
    endgenerate

    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_ROTATIONS_CYCS; i = i + 1) begin
            case (i)
                CALC_GIVENS_COEF_MUL_ADD_CYCS: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = COL_ID; j < MAX_N; j = j + 1) begin
                                s[i].meta.r.r[ROW_ID - 1].c[j] <= tmp1_r[j - COL_ID].meta;
                                s[i].meta.r.r[ROW_ID].c[j] <= tmp2_r[j - COL_ID].meta;
                                s[i].meta.a.r[ROW_ID - 1].c[j] <= tmp1_a[j - COL_ID].meta;
                                s[i].meta.a.r[ROW_ID].c[j] <= tmp2_a[j - COL_ID].meta;
                            end
                            if (COL_ID > 0) begin
                                s[i].meta.a.r[ROW_ID - 1].c[COL_ID - 1] <= pre_diag.meta;
                                s[i].meta.a.r[ROW_ID].c[COL_ID - 1] <= 0;
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
                            for (int j = 0; j <= ROW_ID + 1; j = j + 1) begin
                                if (j < MAX_N) begin
                                    s[i].meta.a.r[j].c[COL_ID] <= tmp3_a[j].meta;
                                    s[i].meta.a.r[j].c[COL_ID + 1] <= tmp4_a[j].meta;
                                end
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

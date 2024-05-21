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

    // [       c,       s]  [conj(c),   -s]
    // [-conj(s), conj(c)]  [conj(s),    c]
    // R <- G * R
    // Q <- Q * Hermite(G)
    // A <- G * A * Hermite(G)

    genvar i;
    generate
        for (i = 1; i <= CALC_GIVENS_COEF_C_S_CYCS + 1; i = i + 1) begin
            case (i)
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

`timescale 1ns / 1ps

`include "complex.vh"

module sampling_coefs # (
    parameter DIV_N = SAMPLING_DIV_N,
    parameter STEP_COEF = SAMPLING_STEP_COEF
) (
    input wire clk,
    input wire rst,
    input wire sample_mode_axis spm,

    output wire cp_axis t1,
    output wire cp_axis t2
);
    logic cnt_valid;
    logic signed [DATA_WIDTH - 1:0] t1_cnt, t2_cnt;
    float_axis step, t1_cnt_fl, t2_cnt_fl;
    float_axis t1_tmp, t2_tmp;
    cp_axis t1_circle, t2_circle;
    floating_mul_0 fl_mul_0 (
        .aclk(clk),
        .s_axis_a_tdata(spm.meta.range),
        .s_axis_a_tvalid(spm.valid),
        .s_axis_b_tdata(STEP_COEF),
        .s_axis_b_tvalid(1'b1),
        .m_axis_result_tdata(step.meta),
        .m_axis_result_tvalid(step.valid)
    );

    integer_to_floating_0 int_to_fl_1 (
        .aclk(clk),
        .s_axis_a_tdata(t1_cnt),
        .s_axis_a_tvalid(cnt_valid),
        .m_axis_result_tdata(t1_cnt_fl.meta),
        .m_axis_result_tvalid(t1_cnt_fl.valid)
    );

    integer_to_floating_0 int_to_fl_2 (
        .aclk(clk),
        .s_axis_a_tdata(t2_cnt),
        .s_axis_a_tvalid(cnt_valid),
        .m_axis_result_tdata(t2_cnt_fl.meta),
        .m_axis_result_tvalid(t2_cnt_fl.valid)
    );

    floating_mul_0 fl_mul_1 (
        .aclk(clk),
        .s_axis_a_tdata(t1_cnt_fl.meta),
        .s_axis_a_tvalid(t1_cnt_fl.valid),
        .s_axis_b_tdata(step.meta),
        .s_axis_b_tvalid(step.valid),
        .m_axis_result_tdata(t1_tmp.meta),
        .m_axis_result_tvalid(t1_tmp.valid)
    );

    floating_mul_0 fl_mul_2 (
        .aclk(clk),
        .s_axis_a_tdata(t2_cnt_fl.meta),
        .s_axis_a_tvalid(t2_cnt_fl.valid),
        .s_axis_b_tdata(step.meta),
        .s_axis_b_tvalid(step.valid),
        .m_axis_result_tdata(t2_tmp.meta),
        .m_axis_result_tvalid(t2_tmp.valid)
    );

    real2circle real_to_circle_1 (
        clk, rst, 
        {t1_tmp.valid & !spm.meta.mode, t1_tmp.meta},
        t1_circle
    );
    real2circle real_to_circle_2 (
        clk, rst, 
        {t2_tmp.valid & !spm.meta.mode, t2_tmp.meta},
        t2_circle
    );

    assign t1 = spm.meta.mode ? {t1_tmp.valid, {t1_tmp.meta, 32'b0}} : t1_circle;
    assign t2 = spm.meta.mode ? {t2_tmp.valid, {t2_tmp.meta, 32'b0}} : t2_circle;

    sampling_status_t stat;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_SAMP_IDLE;
            cnt_valid <= 0;
        end else begin
            case (stat)
                ST_SAMP_IDLE: begin
                    if (spm.valid) begin
                        stat <= ST_SAMP_CALC_STEP;
                    end
                end
                ST_SAMP_CALC_STEP: begin
                    if (step.valid) begin
                        stat <= ST_SAMP_SAMPLING;
                        t1_cnt <= -DIV_N + 1;
                        t2_cnt <= -DIV_N + 1;
                        cnt_valid <= 1;
                    end
                end
                ST_SAMP_SAMPLING: begin
                    t2_cnt <= t2_cnt + 1;
                    if (t2_cnt == DIV_N) begin
                        t2_cnt <= -DIV_N + 1;
                        if (t1_cnt == DIV_N) begin
                            cnt_valid <= 0;
                            t1_cnt <= 0;
                            t2_cnt <= 0;
                            stat <= ST_SAMP_FIN;
                        end else begin
                            t1_cnt <= t1_cnt + 1;
                        end
                    end
                end
                ST_SAMP_FIN: begin

                end
                default: begin

                end
            endcase
        end
    end


endmodule

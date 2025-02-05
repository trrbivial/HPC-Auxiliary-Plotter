
`timescale 1ns / 1ps

`include "complex.vh"

module qr_decomp # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire mat_axis in,
    input wire [2:0] mat_n,

    output wire roots_axis out,
    output wire in_ready
);

    qr_decomp_status_t stat;

    qr_axis select_in;
    qr_axis single_shift_sub_out;

    single_shift #(SHIFT_SUB) m_single_shift_sub (
        .clk(clk),
        .rst(rst),
        .in(select_in),
        .out(single_shift_sub_out)
    );

    qr_axis givens_rotation_out;

    givens_rotations m_givens_rotations (
        .clk(clk),
        .rst(rst),
        .in(single_shift_sub_out),
        .out(givens_rotation_out)
    );

    qr_axis mul_mat_out;


    mul_givens_mat m_mul_givens_mat (
        .clk(clk),
        .rst(rst),
        .in(givens_rotation_out),
        .out(mul_mat_out)
    );

    qr_axis final_module_out;

    single_shift #(SHIFT_ADD) m_single_shift_add (
        .clk(clk),
        .rst(rst),
        .in(mul_mat_out),
        .out(final_module_out)
    );

    qr_axis out_cache;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_cache.valid <= 0;
        end else begin
            out_cache <= final_module_out;
        end
    end

    logic in_ready_reg;
    assign in_ready = in_ready_reg;

    logic [9:0] count_input;
    logic [9:0] count_total;
    logic [9:0] count_output;
    logic output_end;
    assign output_end = count_output == count_total;

    roots_axis out_reg;
    
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_QR_INIT;
            out_reg <= 0;
            count_input <= 0;
            count_total <= 0;
            count_output <= 0;
            select_in <= 0;
            in_ready_reg <= 1;
        end else begin
            out_reg.valid <= 0;
            case (stat)
                ST_QR_INIT: begin
                    if (~output_end) begin
                        out_reg.valid <= out_cache.valid;
                        for (int i = 0; i < MAX_DEG; i = i + 1) begin
                            out_reg.meta.x[i] <= out_cache.meta.r.r[i].c[i];
                        end
                        count_output <= count_output + 1;
                    end
                    if (in.valid & in_ready) begin
                        select_in.valid <= 1;
                        select_in.meta.r <= in.meta;
                        select_in.meta.row_id <= 1;
                        select_in.meta.col_id <= 0;
                        select_in.meta.lim <= mat_n;
                        select_in.meta.dir <= 0;
                        select_in.meta.mul_mat_pos <= 0;
                        select_in.meta.shift <= SHIFT_SUB;
                        count_input <= 1;
                        stat <= ST_QR_FROM_INPUT;
                    end
                end
                ST_QR_FROM_INPUT: begin
                    select_in.valid <= in.valid;
                    select_in.meta.r <= in.meta;
                    select_in.meta.row_id <= 1;
                    select_in.meta.col_id <= 0;
                    select_in.meta.lim <= mat_n;
                    select_in.meta.dir <= 0;
                    select_in.meta.mul_mat_pos <= 0;
                    select_in.meta.shift <= SHIFT_SUB;
                    count_input <= count_input + 1;

                    if (~output_end) begin
                        out_reg.valid <= out_cache.valid;
                        for (int i = 0; i < MAX_DEG; i = i + 1) begin
                            out_reg.meta.x[i] <= out_cache.meta.r.r[i].c[i];
                        end
                        count_output <= count_output + 1;
                    end

                    if (final_module_out.valid && output_end) begin
                        in_ready_reg <= 0;
                        count_total <= count_input + 1;
                        count_output <= 0;
                        stat <= ST_QR_FROM_MUL_MAT;
                    end
                end
                ST_QR_FROM_MUL_MAT: begin
                    select_in <= out_cache;
                    select_in.meta.shift <= 0;
                    select_in.meta.mul_mat_pos <= out_cache.meta.mul_mat_pos + 1;
                    if (out_cache.meta.should_reset_mul_mat_pos) begin
                        select_in.meta.row_id <= out_cache.meta.row_id + 1;
                        select_in.meta.col_id <= out_cache.meta.col_id + 1;
                        select_in.meta.mul_mat_pos <= 0;
                    end
                    if (out_cache.meta.should_reset_row_id) begin
                        select_in.meta.row_id <= 1;
                        select_in.meta.col_id <= 0;
                        select_in.meta.dir <= out_cache.meta.dir ^ 1'b1;
                    end
                    if (out_cache.meta.should_start_new_iter) begin
                        select_in.meta.iter <= out_cache.meta.iter + 1;
                        select_in.meta.shift <= SHIFT_SUB;
                    end
                    if (out_cache.meta.should_reduce_problem_scale) begin
                        select_in.meta.iter <= 0;
                        select_in.meta.lim <= out_cache.meta.lim - 1;
                    end
                    if (out_cache.meta.should_output) begin
                        select_in <= 0;
                        out_reg.valid <= out_cache.valid;
                        for (int i = 0; i < MAX_DEG; i = i + 1) begin
                            out_reg.meta.x[i] <= out_cache.meta.r.r[i].c[i];
                        end
                        in_ready_reg <= 1;
                        count_output <= 1;
                        stat <= ST_QR_INIT;
                    end
                end
                default: begin
                end
            endcase
        end
    end
    assign out = out_reg;
endmodule

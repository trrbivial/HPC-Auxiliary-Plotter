`timescale 1ns / 1ps

`include "complex.vh"

module single_shift # (
    parameter TYPE = SHIFT_SUB
) (
    input wire clk,
    input wire rst,
    input wire qr_axis in,

    output wire qr_axis out
); 
    localparam MAX_N = MAX_DEG;

    qr_axis s[CP_ADD_CYCS + 1:0];
    cp_axis tmp[MAX_N - 1:0];

    logic [2:0] lim;
    assign s[0] = in;
    assign lim = in.meta.lim;

    cp_axis delta;
    assign delta.valid = in.valid;
    assign delta.meta = 
        in.meta.shift == SHIFT_SUB ? `neg_cp(in.meta.r.r[lim].c[lim]) :
        in.meta.shift == SHIFT_ADD ? in.meta.offset :
        0;

    genvar i;
    generate
        for (i = 0; i < MAX_N; i = i + 1) begin
            complex_adder cp_add_i (
                clk, 
                {in.valid, in.meta.r.r[i].c[i]},
                delta,
                tmp[i]
            );
        end
    endgenerate

    generate
        for (i = 1; i <= CP_ADD_CYCS + 1; i = i + 1) begin
            case (i)
                1: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_SUB && s[i - 1].meta.shift == SHIFT_SUB) begin
                                s[i].meta.offset <= s[i - 1].meta.r.r[s[i - 1].meta.lim].c[s[i - 1].meta.lim];
                            end
                        end
                    end
                end
                2: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_ADD) begin
                                s[i].meta.should_run_shift_add <= 
                                    (s[i - 1].meta.row_id + 1 == s[i - 1].meta.lim) &
                                    (s[i - 1].meta.dir);
                            end
                        end
                    end
                end
                3: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_ADD) begin
                                s[i].meta.should_reset_row_id <= 
                                    (s[i - 1].meta.row_id == s[i - 1].meta.lim);
                            end
                        end
                    end
                end
                4: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_ADD) begin
                                s[i].meta.should_start_new_iter <= 
                                    (s[i - 1].meta.should_reset_row_id) &
                                    (s[i - 1].meta.dir);
                            end
                        end
                    end
                end
                5: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_ADD) begin
                                s[i].meta.should_reduce_problem_scale <= 
                                    (s[i - 1].meta.should_start_new_iter) &
                                    (s[i - 1].meta.iter == ITER_TIMES_EACH);
                            end
                        end
                    end
                end
                6: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == SHIFT_ADD) begin
                                s[i].meta.should_output <= 
                                    (s[i - 1].meta.should_reduce_problem_scale) &
                                    (s[i - 1].meta.lim == 2);
                            end
                        end
                    end

                end
                CP_ADD_CYCS + 1: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (TYPE == s[i - 1].meta.shift) begin
                                for (int j = 0; j < MAX_N; j = j + 1) begin
                                    s[i].meta.r.r[j].c[j] <= tmp[j].meta;
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
    assign out = s[CP_ADD_CYCS + 1];

endmodule

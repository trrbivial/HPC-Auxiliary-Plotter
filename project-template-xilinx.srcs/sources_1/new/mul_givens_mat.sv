`timescale 1ns / 1ps

`include "complex.vh"

module mul_givens_mat # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire qr_axis in,
    output wire qr_axis out
);
    qr_axis s[CP_MUL_ADD_CYCS + 1:0];

    assign s[0] = in;

    logic [2:0] col_id;
    logic [2:0] row_id;
    logic dir;
    assign col_id = in.meta.col_id;
    assign row_id = in.meta.row_id;
    assign dir = in.meta.dir;


    cp_axis in1[MAX_N - 1:0];
    cp_axis c1[1:0];
    cp_axis in2[MAX_N - 1:0];
    cp_axis c2[1:0];
    cp_axis out0[MAX_N - 1:0];
    cp_axis out1[MAX_N - 1:0];

    assign c1[0] = {in.valid, dir ? `conj(in.meta.c[col_id]) : in.meta.c[col_id]};
    assign c2[0] = {in.valid, dir ? `conj(in.meta.s[col_id]) : in.meta.s[col_id]};
    assign c1[1] = {in.valid, dir ? `neg_cp(in.meta.s[col_id]) : {`neg_fl(in.meta.s[col_id].r), in.meta.s[col_id].i}};
    assign c2[1] = {in.valid, dir ? in.meta.c[col_id] : `conj(in.meta.c[col_id])};

    genvar i;
    generate
        for (i = 0; i < MAX_N; i = i + 1) begin
            assign in1[i] = {in.valid, dir ? in.meta.r.r[i].c[col_id] : in.meta.r.r[col_id].c[i]};
            assign in2[i] = {in.valid, dir ? in.meta.r.r[i].c[row_id] : in.meta.r.r[row_id].c[i]};
        end
    endgenerate

    generate
        for (i = 0; i < MAX_N; i = i + 1) begin
            complex_mul_adder cp_mul_add_0 (
                clk, 
                in1[i], c1[0],
                in2[i], c2[0],
                out0[i]
            );
            complex_mul_adder cp_mul_add_1 (
                clk, 
                in1[i], c1[1],
                in2[i], c2[1],
                out1[i]
            );
        end
    endgenerate

    generate
        for (i = 1; i <= CP_MUL_ADD_CYCS + 1; i = i + 1) begin
            case (i)
                CP_MUL_ADD_CYCS + 1: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            for (int j = 0; j < MAX_N; j = j + 1) begin
                                if (s[i - 1].meta.dir) begin
                                    s[i].meta.r.r[j].c[s[i - 1].meta.col_id] <= out0[j].meta;
                                    s[i].meta.r.r[j].c[s[i - 1].meta.row_id] <= out1[j].meta;
                                end else begin
                                    s[i].meta.r.r[s[i - 1].meta.col_id].c[j] <= out0[j].meta;
                                    s[i].meta.r.r[s[i - 1].meta.row_id].c[j] <= out1[j].meta;
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

    assign out = s[CP_MUL_ADD_CYCS + 1];

endmodule

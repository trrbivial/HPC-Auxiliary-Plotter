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
    logic [2:0] pos;
    logic dir;
    assign col_id = in.meta.col_id;
    assign row_id = in.meta.row_id;
    assign dir = in.meta.dir;
    assign pos = in.meta.mul_mat_pos;


    cp_axis in1;
    cp_axis c1[1:0];
    cp_axis in2;
    cp_axis c2[1:0];
    cp_axis out0;
    cp_axis out1;

    assign c1[0] = {in.valid, dir ? `conj(in.meta.c[col_id]) : in.meta.c[col_id]};
    assign c2[0] = {in.valid, dir ? `conj(in.meta.s[col_id]) : in.meta.s[col_id]};
    assign c1[1] = {in.valid, dir ? `neg_cp(in.meta.s[col_id]) : {`neg_fl(in.meta.s[col_id].r), in.meta.s[col_id].i}};
    assign c2[1] = {in.valid, dir ? in.meta.c[col_id] : `conj(in.meta.c[col_id])};

    assign in1 = {in.valid, dir ? in.meta.r.r[pos].c[col_id] : in.meta.r.r[col_id].c[pos]};
    assign in2 = {in.valid, dir ? in.meta.r.r[pos].c[row_id] : in.meta.r.r[row_id].c[pos]};

    complex_mul_adder cp_mul_add_0 (
        clk, 
        in1, c1[0],
        in2, c2[0],
        out0
    );
    complex_mul_adder cp_mul_add_1 (
        clk, 
        in1, c1[1],
        in2, c2[1],
        out1
    );

    genvar i;
    generate
        for (i = 1; i <= CP_MUL_ADD_CYCS + 1; i = i + 1) begin
            case (i)
                CP_MUL_ADD_CYCS + 1: begin
                    always_ff @(posedge clk or posedge rst) begin
                        if (rst) begin
                            s[i].valid <= 0;
                        end else begin
                            s[i] <= s[i - 1];
                            if (s[i - 1].meta.dir) begin
                                s[i].meta.r.r[s[i - 1].meta.mul_mat_pos].c[s[i - 1].meta.col_id] <= out0.meta;
                                s[i].meta.r.r[s[i - 1].meta.mul_mat_pos].c[s[i - 1].meta.row_id] <= out1.meta;
                            end else begin
                                s[i].meta.r.r[s[i - 1].meta.col_id].c[s[i - 1].meta.mul_mat_pos] <= out0.meta;
                                s[i].meta.r.r[s[i - 1].meta.row_id].c[s[i - 1].meta.mul_mat_pos] <= out1.meta;
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

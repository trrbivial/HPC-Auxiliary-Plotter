`timescale 1ns / 1ps

`include "complex.vh"

module givens_rotations_tb();

    reg clk;
    reg rst;

    mat mat_identity;
    mat mat_r;
    logic valid;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, givens_rotations_tb);
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        for (integer i = 0; i < MAX_DEG; i = i + 1) begin
            for (integer j = 0; j < MAX_DEG; j = j + 1) begin
                mat_identity.r[i].c[j] = (i == j) ? ONE_CP : 0;
                mat_r.r[i].c[j] = (i == j + 1) ? ONE_CP : 0;
            end
        end
        mat_r.r[0].c[0] = {32'h3F800000, 32'h40C00000};
        mat_r.r[0].c[1] = {32'h40000000, 32'h40A00000};
        mat_r.r[0].c[2] = {32'h40400000, 32'h40800000};
        mat_r.r[0].c[3] = {32'h40800000, 32'h40400000};
        mat_r.r[0].c[4] = {32'h40A00000, 32'h40000000};
        mat_r.r[0].c[5] = {32'h40C00000, 32'h3F800000};

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #100;
        valid = 1;



        #500000;
        $finish;
    end

    always #5 clk = ~clk; // 100MHz

    qr_axis in, out;
    assign in.valid = valid;
    assign in.meta.q = mat_identity;
    assign in.meta.r = mat_r;

    givens_rotations #(1, 0) dut (
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out)
    );

endmodule


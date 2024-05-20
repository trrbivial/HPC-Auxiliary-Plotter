`timescale 1ns / 1ps

`include "complex.vh"

module assign_tb();

    reg clk;
    reg rst;
    qr_axis out_reg;

    initial begin
        //$dumpfile("dump.vcd");
        //$dumpvars(0, mod_top_tb);
        clk = 1'b0;
        rst = 1'b0;
        out_reg = 0;
        out_reg.valid = 1;
        out_reg.meta.r.r[0].c[0] = ONE_CP;
        out_reg.meta.r.r[1].c[1] = ONE_CP;
        out_reg.meta.r.r[2].c[2] = ONE_CP;
        out_reg.meta.r.r[3].c[3] = ONE_CP;
        out_reg.meta.r.r[4].c[4] = ONE_CP;
        out_reg.meta.r.r[5].c[5] = ONE_CP;

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #500000;
        //$finish;
    end

    always #5 clk = ~clk; // 100MHz

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out <= 0;
        end else begin
            for (int i = 0; i < MAX_DEG; i = i + 1) begin
                out.meta.x[i] <= out_reg.meta.r.r[i].c[i];
            end
        end
    end

    roots_axis out;



    /*
    genvar i;
    generate 
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign out.meta.x[i] = out_reg.meta.r.r[i].c[i];
        end
    endgenerate
    */

endmodule


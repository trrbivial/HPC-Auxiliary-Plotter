`timescale 1ns / 1ps

`include "complex.vh"

module circle_chart (
    input wire clk,
    input wire rst,
    input wire cnt_valid,
    input wire [DATA_WIDTH - 1:0] t1_cnt,
    input wire [DATA_WIDTH - 1:0] t2_cnt,
    
    output wire cp_axis t1_circle,
    output wire cp_axis t2_circle
);
    logic valid;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            valid <= 0;
        end else begin
            valid <= cnt_valid;
        end
    end

    bram_of_cos_sin_chart m_bram_of_cos_sin_chart (
        .clka(clk),
        .ena(cnt_valid),
        .addra(t1_cnt[10:0]),
        .douta(t1_circle.meta),

        .clkb(clk),
        .enb(cnt_valid),
        .addrb(t2_cnt[10:0]),
        .doutb(t2_circle.meta)
    );

    assign t1_circle.valid = valid;
    assign t2_circle.valid = valid;


endmodule

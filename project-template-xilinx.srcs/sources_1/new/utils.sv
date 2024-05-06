`timescale 1ns / 1ps

module reg_ctrl #(
    parameter DATA_WIDTH = 32
) (
    output reg [DATA_WIDTH-1:0] out,
    input wire [DATA_WIDTH-1:0] in,
    input wire we,
    input wire rst,
    input wire [DATA_WIDTH-1:0] rst_val,
    input wire clk
);
    always_ff @(posedge clk) begin
        if (rst) begin
            out <= rst_val;
        end else if (we) begin
            out <= in;
        end
    end
endmodule

module reg_pipe #(
    parameter DATA_WIDTH = 32
) (
    output reg [DATA_WIDTH-1:0] out,
    input wire [DATA_WIDTH-1:0] in,
    input wire stall,
    input wire bubble,
    input wire [DATA_WIDTH-1:0] bubble_val,
    input wire clk
);
    reg_ctrl #(DATA_WIDTH) r(
        .out        (out),
        .in         (in),
        .we         (~stall),
        .rst        (bubble),
        .rst_val    (bubble_val),
        .clk        (clk)
    );
endmodule

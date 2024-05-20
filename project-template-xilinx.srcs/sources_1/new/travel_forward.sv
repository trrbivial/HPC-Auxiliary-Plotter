`timescale 1ns / 1ps

`include "complex.vh"

module travel_forward #(
    parameter WIDTH = 12, FORWARD = 1, HSIZE = 0, HMAX = 0, VSIZE = 0, VMAX = 0
) (
    input wire clk,
    input wire [WIDTH - 1:0] hdata,   // ꣬horizontal
    input wire [WIDTH - 1:0] vdata,   // ꣬vertical
    input wire data_enable,

    output reg [20:0] addr
);
    initial begin
        addr = FORWARD;
    end

    always @ (posedge clk)
    begin
        if (data_enable)
        begin
            if (addr == VGA_ADDR_MAX - 1)
                addr <= 0;
            else
                addr <= addr + 1;
        end
    end

    
endmodule


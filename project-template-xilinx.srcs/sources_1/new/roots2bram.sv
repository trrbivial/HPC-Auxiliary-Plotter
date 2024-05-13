`timescale 1ns / 1ps

`include "complex.vh"

module roots2bram (
    input wire clk,
    input wire rst,
    input wire roots_axis in,

    output wire [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr,
    output wire bram_we,
    output wire [CP_DATA_WIDTH - 1:0] bram_data[MAX_DEG - 1:0]
);
    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr_reg;
    assign bram_we = in.valid ? 1'b1 : 1'b0;
    assign bram_addr = bram_addr_reg;
    
    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign bram_data[i] = in.meta.x[i];
        end
    endgenerate

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            bram_addr_reg <= 0;
        end else begin
            if (in.valid) begin
                bram_addr_reg <= bram_addr_reg + 1;
            end
        end
    end

endmodule

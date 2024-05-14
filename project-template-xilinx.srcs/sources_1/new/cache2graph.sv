`timescale 1ns / 1ps

`include "complex.vh"

module cache2graph (
    input wire clk,
    input wire rst,
    input wire [BRAM_1024_ADDR_WIDTH - 1:0] rear,
    input wire [CP_DATA_WIDTH - 1:0] bram_data,
    input wire [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_a_out_data,

    output wire [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr[MAX_DEG - 1:0],
    output wire [2:0] ind,
    output wire [BRAM_524288_ADDR_WIDTH - 1:0] graph_memory_a_addr,
    output wire [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_a_in_data,
    output wire graph_memory_a_we
);
    logic is_head_eq_rear;
    assign is_head_eq_rear = bram_addr_reg[index] == rear;

    logic [2:0] index;
    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr_reg[MAX_DEG - 1:0];

    assign ind = index;
    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign bram_addr[i] = bram_addr_reg[i];
        end
    endgenerate

    pixel now_pixel;
    logic [DATA_WIDTH - 1:0] now_pixel_index;
    logic graph_memory_a_we_reg;

    assign graph_memory_a_we = graph_memory_a_we_reg;
    assign graph_memory_a_addr = now_pixel_index[BRAM_524288_ADDR_WIDTH + 1: 2];
    

    pixel2graph_status_t stat;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= IDLE;
            index <= 0;
            now_pixel_index <= 0;
            graph_memory_a_we_reg <= 0;
            for (int i = 0; i < MAX_DEG; i = i + 1) begin
                bram_addr[i] <= 0;
            end
        end else begin
            if (is_head_eq_rear) begin
                stat <= IDLE;
                index <= index + 1;
                if (index == MAX_DEG - 1) begin
                    index <= 0;
                end
            end else begin
                case (stat) 
                    IDLE: begin
                        now_pixel <= bram_data;
                        stat <= CHECK;
                    end
                    CHECK: begin
                        if (now_pixel.x < 0 || now_pixel.y < 0 || now_pixel.x >= VGA_HSIZE || now_pixel.y >= VGA_VSIZE) begin
                            stat <= IDLE;
                        end else begin
                            now_pixel_index <= (VGA_VSIZE - 1 - now_pixel.y) * VGA_HSIZE + now_pixel.x;
                            stat <= READ_PIXEL;
                        end
                    end
                    READ_PIXEL: begin

                    end
                    NEXT: begin
                        bram_b_addr[index] <= bram_b_addr[index] + 1;
                        stat <= IDLE;
                    end
                    default: begin

                    end
                endcase
                
            end
        end
    end
endmodule

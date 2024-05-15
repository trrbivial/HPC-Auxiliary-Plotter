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
    output wire graph_memory_a_we,
    output wire graph_memory_op_finished
);
    logic [2:0] index;
    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr_reg[MAX_DEG - 1:0];

    logic is_head_eq_rear;
    assign is_head_eq_rear = bram_addr_reg[index] == rear;
    assign graph_memory_op_finished = is_head_eq_rear;


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
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_a_in_data_reg;
    assign graph_memory_a_we = graph_memory_a_we_reg;
    assign graph_memory_a_addr = now_pixel_index[BRAM_524288_ADDR_WIDTH + 1: 2];
    assign graph_memory_a_in_data = graph_memory_a_in_data_reg;
    

    pixel2graph_status_t stat;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_P2G_IDLE;
            index <= 0;
            now_pixel_index <= 0;
            graph_memory_a_we_reg <= 0;
            for (int i = 0; i < MAX_DEG; i = i + 1) begin
                bram_addr_reg[i] <= 0;
            end
        end else begin
            if (is_head_eq_rear) begin
                stat <= ST_P2G_IDLE;
                index <= index + 1;
                if (index == MAX_DEG - 1) begin
                    index <= 0;
                end
            end else begin
                case (stat) 
                    ST_P2G_IDLE: begin
                        now_pixel <= bram_data;
                        stat <= ST_P2G_CHECK;
                    end
                    ST_P2G_CHECK: begin
                        if (now_pixel.x < 0 || now_pixel.y < 0 || now_pixel.x >= VGA_HSIZE || now_pixel.y >= VGA_VSIZE) begin
                            stat <= ST_P2G_NEXT;
                        end else begin
                            now_pixel_index <= (VGA_VSIZE - 1 - now_pixel.y) * VGA_HSIZE + now_pixel.x;
                            stat <= ST_P2G_READ_PIXEL;
                        end
                    end
                    ST_P2G_READ_PIXEL: begin
                        stat <= ST_P2G_WRITE_PIXEL;
                    end
                    ST_P2G_WRITE_PIXEL: begin
                        graph_memory_a_in_data_reg <= graph_memory_a_out_data;
                        graph_memory_a_we_reg <= 1;
                        case (now_pixel_index[1:0])
                            2'b00: graph_memory_a_in_data_reg[ 3: 0] <= graph_memory_a_out_data[ 3: 0] == 4'b1111 ? 4'b1111 : graph_memory_a_out_data[ 3: 0] + 1;
                            2'b01: graph_memory_a_in_data_reg[ 7: 4] <= graph_memory_a_out_data[ 7: 4] == 4'b1111 ? 4'b1111 : graph_memory_a_out_data[ 7: 4] + 1;
                            2'b10: graph_memory_a_in_data_reg[11: 8] <= graph_memory_a_out_data[11: 8] == 4'b1111 ? 4'b1111 : graph_memory_a_out_data[11: 8] + 1;
                            2'b11: graph_memory_a_in_data_reg[15:12] <= graph_memory_a_out_data[15:12] == 4'b1111 ? 4'b1111 : graph_memory_a_out_data[15:12] + 1;
                            default: begin
                            end
                        endcase
                        stat <= ST_P2G_NEXT;
                    end
                    ST_P2G_NEXT: begin
                        bram_addr_reg[index] <= bram_addr_reg[index] + 1;
                        graph_memory_a_we_reg <= 0;
                        graph_memory_a_in_data_reg <= 0;
                        stat <= ST_P2G_IDLE;
                    end
                    default: begin

                    end
                endcase
                
            end
        end
    end
endmodule

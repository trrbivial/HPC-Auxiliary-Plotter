`timescale 1ns / 1ps

`include "complex.vh"

module cache2graph (
    input wire clk,
    input wire rst,
    input wire [BRAM_1024_ADDR_WIDTH - 1:0] rear,
    input wire [CP_DATA_WIDTH - 1:0] bram_data,
    input wire wbm_signal_recv wbm_i,

    output wire [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr[MAX_DEG - 1:0],
    output wire [2:0] ind,
    output wire wbm_signal_send wbm_o,
    output wire graph_memory_op_finished
);
    wbm_signal_send wbm_o_reg;

    assign wbm_o = wbm_o_reg;

    logic [2:0] index;
    assign ind = index;

    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_addr_reg[MAX_DEG - 1:0];
    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign bram_addr[i] = bram_addr_reg[i];
        end
    endgenerate

    logic is_head_eq_rear;
    assign is_head_eq_rear = bram_addr_reg[index] == rear;
    assign graph_memory_op_finished = is_head_eq_rear;


    pixel now_pixel;
    logic [DATA_WIDTH - 1:0] now_pixel_index;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] dat;

    pixel2graph_status_t stat;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_P2G_IDLE;
            index <= 0;
            now_pixel_index <= 0;
            wbm_o_reg <= 0;
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
                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.adr <= now_pixel_index[BRAM_524288_ADDR_WIDTH + 1: 2];
                        wbm_o_reg.dat <= 0;
                        wbm_o_reg.we <= 0;
                        stat <= ST_P2G_WAIT_READ_ACK;
                    end
                    ST_P2G_WAIT_READ_ACK: begin
                        if (wbm_i.ack) begin
                            wbm_o_reg.cyc <= 0;
                            wbm_o_reg.stb <= 0;
                            dat <= wbm_i.dat;
                            stat <= ST_P2G_WRITE_PIXEL;
                        end
                    end
                    ST_P2G_WRITE_PIXEL: begin
                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.we <= 1;
                        wbm_o_reg.dat <= dat;
                        case (now_pixel_index[1:0])
                            2'b00: wbm_o_reg.dat[ 3: 0] <= dat[ 3: 0] == 4'b1111 ? 4'b1111 : dat[ 3: 0] + 1;
                            2'b01: wbm_o_reg.dat[ 7: 4] <= dat[ 7: 4] == 4'b1111 ? 4'b1111 : dat[ 7: 4] + 1;
                            2'b10: wbm_o_reg.dat[11: 8] <= dat[11: 8] == 4'b1111 ? 4'b1111 : dat[11: 8] + 1;
                            2'b11: wbm_o_reg.dat[15:12] <= dat[15:12] == 4'b1111 ? 4'b1111 : dat[15:12] + 1;
                            default: begin
                            end
                        endcase
                        stat <= ST_P2G_WAIT_WRITE_ACK;
                    end
                    ST_P2G_WAIT_WRITE_ACK: begin
                        if (wbm_i.ack) begin
                            wbm_o_reg <= 0;
                            stat <= ST_P2G_NEXT;
                        end
                    end
                    ST_P2G_NEXT: begin
                        bram_addr_reg[index] <= bram_addr_reg[index] + 1;
                        stat <= ST_P2G_IDLE;
                    end
                    default: begin

                    end
                endcase
                
            end
        end
    end
endmodule

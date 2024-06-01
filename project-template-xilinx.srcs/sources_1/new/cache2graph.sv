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
    logic [$clog2(PACKED_PIXEL_COUNT) - 1:0] pos;
    assign pos = now_pixel_index[$clog2(PACKED_PIXEL_COUNT) - 1:0];

    packed_pixel_data dat;

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
                        if (now_pixel.x < 0 || now_pixel.y < 0 || now_pixel.x >= VGA_HSIZE || now_pixel.y >= VGA_VSIZE - TOP_BAR_WIDTH) begin
                            stat <= ST_P2G_NEXT;
                        end else begin
                            now_pixel_index <= (VGA_VSIZE - 1 - now_pixel.y) * VGA_HSIZE + now_pixel.x;
                            stat <= ST_P2G_READ_PIXEL;
                        end
                    end
                    ST_P2G_READ_PIXEL: begin
                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.we <= 0;
                        wbm_o_reg.adr <= (now_pixel_index >> $clog2(PACKED_PIXEL_COUNT));
                        wbm_o_reg.dat <= 0;
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
                        wbm_o_reg.dat.p[pos] <= (~dat.p[pos] == '0) ? {PIXEL_DATA_WIDTH{1'b1}} : dat.p[pos] + 1;
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

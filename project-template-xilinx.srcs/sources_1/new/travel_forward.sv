`timescale 1ns / 1ps

`include "complex.vh"

module travel_forward #(
    parameter WIDTH = 12, HSIZE = 0, HMAX = 0, VSIZE = 0, VMAX = 0
) (
    input wire clk,
    input wire [WIDTH - 1:0] hdata,   // ꣬horizontal
    input wire [WIDTH - 1:0] vdata,   // ꣬vertical
    input wire data_enable,
    input wire wb_last_op_finished,
    input wire packed_pixel_data data,

    output reg [$clog2(BRAM_GRAPH_MEM_DEPTH) - 1:0] addr,
    output reg enb,
    output reg vga_is_reading,
    output wire pixel_data pixel
);
    typedef enum logic [2:0] {
        INIT,
        WAIT_LAST_OP_FINISH,
        READ_NEXT_PACK,
        READ_NEXT_PACK1,
        READ_NEXT_PACK2,
        READ_NEXT_PACK3,
        WAIT_NEXT_PACK
    } state_t;

    state_t stat;
    packed_pixel_data now_data_reg;
    packed_pixel_data next_data_reg;
    assign pixel = 
        data_enable ? now_data_reg.p[hdata[$clog2(PACKED_PIXEL_COUNT) - 1:0]] : 
        0;

    initial begin
        stat = INIT;
        enb = 'b0;
        addr = 'b1; 
        vga_is_reading = 'b0;
        now_data_reg = 'b0;
    end
    always @ (posedge clk) begin
        if (data_enable) begin
            case (stat)
                INIT: begin
                    vga_is_reading <= 1;
                    stat <= WAIT_LAST_OP_FINISH;
                end
                WAIT_LAST_OP_FINISH: begin
                    if (wb_last_op_finished) begin
                        enb <= 1;
                        stat <= READ_NEXT_PACK;
                    end
                end
                READ_NEXT_PACK: begin
                    stat <= READ_NEXT_PACK1;
                end
                READ_NEXT_PACK1: begin
                    stat <= READ_NEXT_PACK2;
                end
                READ_NEXT_PACK2: begin
                    stat <= READ_NEXT_PACK3;
                end
                READ_NEXT_PACK3: begin
                    next_data_reg <= data;
                    vga_is_reading <= 0;
                    addr <= addr + 1;
                    if (addr == GM_ADDR_MAX - 1) begin
                        addr <= 0;
                    end
                    enb <= 0;
                    stat <= WAIT_NEXT_PACK;
                end
                WAIT_NEXT_PACK: begin
                    if (hdata[3:0] == 4'b1111) begin
                        now_data_reg <= next_data_reg;
                        stat <= INIT;
                    end
                end
            endcase
        end
    end

    
endmodule


`timescale 1ns / 1ps

`include "complex.vh"

module travel_forward #(
    parameter WIDTH = 12, HSIZE = 0, HMAX = 0, VSIZE = 0, VMAX = 0
) (
    input wire clk,
    input wire [WIDTH - 1:0] hdata,   // ꣬horizontal
    input wire [WIDTH - 1:0] vdata,   // ꣬vertical
    input wire data_enable,
    input wire packed_pixel_data data,

    output reg [$clog2(BRAM_GRAPH_MEM_DEPTH) - 1:0] addr,
    output reg enb,
    output reg [7:0] pixel,
    output reg vga_is_reading
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

    initial begin
        stat = INIT;
        enb = 'b0;
        addr = 'b1; 
        now_data_reg = 'b0;
        vga_is_reading = 'b1;
        pixel = 'b0;
    end
    always @ (posedge clk) begin
        vga_is_reading <= 0;
        if (data_enable || (hdata >= HMAX - 5 && vdata + 1 < VSIZE)) begin
            vga_is_reading <= 1;
        end
        if (data_enable) begin
            if (hdata[$clog2(PACKED_PIXEL_COUNT) - 1:0] < 4'b1111) begin
                pixel <= {now_data_reg.p[hdata[$clog2(PACKED_PIXEL_COUNT) - 1:0] + 4'b1], 4'b0000};
            end
            case (stat)
                INIT: begin
                    enb <= 1;
                    stat <= READ_NEXT_PACK;
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
                    addr <= addr + 1;
                    if (addr == HSIZE * VSIZE / PACKED_PIXEL_COUNT - 1) begin
                        addr <= 0;
                    end
                    enb <= 0;
                    stat <= WAIT_NEXT_PACK;
                end
                WAIT_NEXT_PACK: begin
                    if (hdata[3:0] == 4'b1111) begin
                        now_data_reg <= next_data_reg;
                        pixel <= {next_data_reg.p[0], 4'b0000};
                        stat <= INIT;
                    end
                end
            endcase
        end
    end

    
endmodule


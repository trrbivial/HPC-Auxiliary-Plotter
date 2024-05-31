`timescale 1ns / 1ps

`include "complex.vh"

module sram_controller #(
    parameter ADDR_WIDTH = 20
) (
    input wire clk,
    input wire rst,

    input wire sram_signal_send wbs_i,
    output wire sram_signal_recv wbs_o,

    output reg [ADDR_WIDTH - 1:0] sram_addr,
    inout wire [DATA_WIDTH - 1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [DATA_WIDTH / 8 - 1:0] sram_be_n
);
    wire [DATA_WIDTH - 1:0] sram_data_i;
    logic [DATA_WIDTH - 1:0] sram_data_o;
    logic sram_data_t;
    assign sram_data   = sram_data_t ? 'bz : sram_data_o;
    assign sram_data_i = sram_data;

    enum logic [2:0] {
        INIT,
        READ,
        READ1,
        WRITE1,
        WRITE2
    } stat;

    logic [ADDR_WIDTH - 1:0] addr_reg;
    logic [DATA_WIDTH - 1:0] data_reg;
    logic [DATA_WIDTH / 8 - 1:0] be_n_reg;

    assign wb_o.ack = stat == READ1 || (stat == INIT && wb_i.we);
    assign wb_o.dat = sram_data_i;


    always_comb begin
        sram_addr = wb_i.adr;
        sram_data_t = ~wb_i.we;
        sram_data_o = wb_i.dat;
        sram_ce_n = stat == INIT && !wb_i.stb;
        sram_oe_n = wb_i.we;
        sram_we_n = stat != WRITE1;

        sram_be_n = 4'b0;
        //sram_be_n = ~wb_i.sel;
        if (stat == WRITE1 || stat == WRITE2) begin
          sram_addr   = addr_reg;
          sram_data_t = 0;
          sram_data_o = data_reg;
          sram_oe_n   = 1;
          sram_be_n   = be_n_reg;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
          stat <= INIT;
          addr_reg <= 0;
          data_reg <= 0;
          be_n_reg <= 0;
        end else begin
            case (stat)
                INIT: begin
                    if (wb_i.cyc && wb_i.stb) begin
                        if (wb_i.we) begin
                            stat <= WRITE1;
                            addr_reg <= sram_addr;
                            data_reg <= sram_data_o;
                            be_n_reg <= sram_be_n;
                        end else begin
                            stat <= READ;
                        end
                    end
                end
                READ: stat <= READ1;
                READ1: stat <= INIT;
                WRITE1: stat <= WRITE2;
                WRITE2: stat <= INIT;
                default: stat <= INIT;
            endcase
        end
    end

endmodule

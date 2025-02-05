`timescale 1ns / 1ps

`include "complex.vh"

module draw_top_bar # (
) (
    input wire clk,
    input wire rst,
    input wire system_status_t sys_stat,
    input wire [2:0] index,
    input wire wbm_signal_recv wbm_i,
    input wire sram_signal_recv sram_wbm_i,

    output wire wbm_signal_send wbm_o,
    output wire sram_signal_send sram_wbm_o,
    output reg draw_top_bar_finished,
    output reg draw_option_finished,
    output reg refresh_option_selection_finished
);
    draw_top_bar_status_t stat;
    wbm_signal_send wbm_o_reg;
    sram_signal_send sram_wbm_o_reg;

    assign wbm_o = wbm_o_reg;
    assign sram_wbm_o = sram_wbm_o_reg;

    logic [SRAM_ADDR_WIDTH - 1:0] addr_lim;
    logic [DATA_WIDTH - 1:0] dat0;
    logic [DATA_WIDTH - 1:0] dat1;

    logic is_first_draw;
    logic [2:0] last_index;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wbm_o_reg <= 0;
            sram_wbm_o_reg <= 0;
            draw_top_bar_finished <= 0;
            draw_option_finished <= 0;
            refresh_option_selection_finished <= 0;
            last_index <= 0;
            is_first_draw <= 1;
            stat <= ST_DTB_IDLE;
        end else begin
            case (stat)
                ST_DTB_IDLE: begin
                    draw_top_bar_finished <= 0;
                    draw_option_finished <= 0;
                    refresh_option_selection_finished <= 0;
                    wbm_o_reg <= 0;
                    sram_wbm_o_reg <= 0;
                    if (sys_stat == ST_SYS_DRAW_TOP_BAR) begin
                        sram_wbm_o_reg.adr <= index * SRAM_TOP_BAR_WIDTH;
                        addr_lim <= (index + 1) * SRAM_TOP_BAR_WIDTH;
                        stat <= ST_DTB_RUNNING;
                    end
                    if (sys_stat == ST_SYS_DRAW_OPTION) begin
                        is_first_draw <= 1;
                        addr_lim <= OPTION_COUNT * SRAM_TOP_BAR_WIDTH;
                        stat <= ST_DTB_RUNNING;
                    end
                    if (sys_stat == ST_SYS_REFRESH_OPTION_SELECTION) begin
                        if (is_first_draw) begin
                            wbm_o_reg.adr <= index * (SRAM_TOP_BAR_WIDTH >> 1);
                            addr_lim <= (index + 1) * (SRAM_TOP_BAR_WIDTH >> 1);
                            stat <= ST_DTB_REFRESH_OPTION_BAR;
                        end else begin
                            wbm_o_reg.adr <= last_index * (SRAM_TOP_BAR_WIDTH >> 1);
                            addr_lim <= (last_index + 1) * (SRAM_TOP_BAR_WIDTH >> 1);
                            stat <= ST_DTB_REFRESH_OPTION_BAR;
                        end
                    end
                end
                ST_DTB_RUNNING: begin
                    if (sram_wbm_o_reg.adr == addr_lim) begin
                        draw_top_bar_finished <= (sys_stat == ST_SYS_DRAW_TOP_BAR);
                        draw_option_finished <= (sys_stat == ST_SYS_DRAW_OPTION);
                        stat <= ST_DTB_FIN;
                    end else begin
                        sram_wbm_o_reg.cyc <= 1;
                        sram_wbm_o_reg.stb <= 1;
                        stat <= ST_DTB_WAIT_READ_ACK1;
                    end
                end
                ST_DTB_WAIT_READ_ACK1: begin
                    if (sram_wbm_i.ack) begin
                        sram_wbm_o_reg.cyc <= 0;
                        sram_wbm_o_reg.stb <= 0;
                        sram_wbm_o_reg.adr <= sram_wbm_o_reg.adr + 1;
                        dat0 <= sram_wbm_i.dat;
                        stat <= ST_DTB_READ2;
                    end
                end
                ST_DTB_READ2: begin
                    sram_wbm_o_reg.cyc <= 1;
                    sram_wbm_o_reg.stb <= 1;
                    stat <= ST_DTB_WAIT_READ_ACK2;
                end
                ST_DTB_WAIT_READ_ACK2: begin
                    if (sram_wbm_i.ack) begin
                        sram_wbm_o_reg.cyc <= 0;
                        sram_wbm_o_reg.stb <= 0;
                        sram_wbm_o_reg.adr <= sram_wbm_o_reg.adr + 1;

                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.we <= 1;
                        wbm_o_reg.dat <= {sram_wbm_i.dat, dat0};
                        stat <= ST_DTB_WAIT_WRITE_ACK;

                    end
                end
                ST_DTB_WAIT_WRITE_ACK: begin
                    if (wbm_i.ack) begin
                        wbm_o_reg.cyc <= 0;
                        wbm_o_reg.stb <= 0;
                        wbm_o_reg.we <= 0;
                        wbm_o_reg.adr <= wbm_o_reg.adr + 1;
                        stat <= ST_DTB_RUNNING;
                    end
                end
                ST_DTB_REFRESH_OPTION_BAR: begin
                    if (wbm_o_reg.adr == addr_lim) begin
                        if (is_first_draw) begin
                            refresh_option_selection_finished <= 1;
                            last_index <= index;
                            is_first_draw <= 0;
                            stat <= ST_DTB_FIN;
                        end else begin
                            is_first_draw <= 1;
                            wbm_o_reg <= 0;
                            wbm_o_reg.adr <= index * (SRAM_TOP_BAR_WIDTH >> 1);
                            addr_lim <= (index + 1) * (SRAM_TOP_BAR_WIDTH >> 1);
                            stat <= ST_DTB_REFRESH_OPTION_BAR;
                        end
                    end else begin
                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.we <= 0;
                        stat <= ST_DTB_READ_OPTION_BAR;
                    end
                end
                ST_DTB_READ_OPTION_BAR: begin
                    if (wbm_i.ack) begin
                        wbm_o_reg.cyc <= 0;
                        wbm_o_reg.stb <= 0;
                        wbm_o_reg.dat <= wbm_i.dat ^ (~'b0);
                        stat <= ST_DTB_WRITE_OPTION_BAR;
                    end
                end
                ST_DTB_WRITE_OPTION_BAR: begin
                    wbm_o_reg.cyc <= 1;
                    wbm_o_reg.stb <= 1;
                    wbm_o_reg.we <= 1;
                    stat <= ST_DTB_WAIT_WRITE_OPTION_BAR;
                end
                ST_DTB_WAIT_WRITE_OPTION_BAR: begin
                    if (wbm_i.ack) begin
                        wbm_o_reg.cyc <= 0;
                        wbm_o_reg.stb <= 0;
                        wbm_o_reg.we <= 0;
                        wbm_o_reg.adr <= wbm_o_reg.adr + 1;
                        stat <= ST_DTB_REFRESH_OPTION_BAR;
                    end
                end
                ST_DTB_FIN: begin
                    draw_top_bar_finished <= 0;
                    draw_option_finished <= 0;
                    refresh_option_selection_finished <= 0;
                    stat <= ST_DTB_IDLE;
                end
                default: begin

                end
            endcase
        end

    end


endmodule

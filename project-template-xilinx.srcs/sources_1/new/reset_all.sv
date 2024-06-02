`timescale 1ns / 1ps

`include "complex.vh"

module reset_all # (
) (
    input wire clk,
    input wire rst,
    input wire system_status_t sys_stat,
    input wire wbm_signal_recv wbm_i,

    output wire wbm_signal_send wbm_o,
    output reg reset_finished
);
    reset_all_status_t stat;
    wbm_signal_send wbm_o_reg;

    assign wbm_o = wbm_o_reg;

    logic tim;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wbm_o_reg <= 0;
            tim <= 0;
            reset_finished <= 0;
            stat <= ST_RST_IDLE;
        end else begin
            case (stat)
                ST_RST_IDLE: begin
                    if (sys_stat == ST_SYS_RESET_ALL || sys_stat == ST_SYS_DRAW_BACKGROUND) begin
                        reset_finished <= 0;
                        wbm_o_reg <= 0;
                        tim <= 0;
                        stat <= ST_RST_RUNNING;
                    end
                end
                ST_RST_RUNNING: begin
                    if (wbm_o_reg.adr == 0 && tim) begin
                        reset_finished <= 1;
                        stat <= ST_RST_FIN;
                    end else begin
                        tim <= 1;
                        wbm_o_reg.cyc <= 1;
                        wbm_o_reg.stb <= 1;
                        wbm_o_reg.we <= 1;
                        stat <= ST_RST_WAIT_WRITE_ACK;
                    end
                end
                ST_RST_WAIT_WRITE_ACK: begin
                    if (wbm_i.ack) begin
                        wbm_o_reg.cyc <= 0;
                        wbm_o_reg.stb <= 0;
                        wbm_o_reg.we <= 0;
                        wbm_o_reg.adr <= wbm_o_reg.adr + 1;
                        stat <= ST_RST_RUNNING;
                    end
                end
                ST_RST_FIN: begin
                    reset_finished <= 0;
                    stat <= ST_RST_IDLE;
                end
                default: begin

                end
            endcase
        end

    end


endmodule

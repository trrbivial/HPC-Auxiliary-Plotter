`timescale 1ns / 1ps

`include "complex.vh"

module system_status (
    input wire clk,
    input wire rst,
    input wire [1:0] calc_mode,
    input wire reset_finished,

    input wire draw_option_finished,

    input wire option_select_changed,
    input wire refresh_option_selection_finished,
    input wire option_select_confirmed,

    input wire draw_top_bar_finished,

    input wire mode1_input_finish,
    input wire mode1_moved_or_scaled,
    input wire mode1_calc_finish,
    input wire mode1_exit,

    output system_status_t system_status

);
    system_status_t stat;
    assign system_status = stat;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_SYS_IDLE;
        end else begin
            case (stat)
                ST_SYS_IDLE: begin
                    stat <= ST_SYS_RESET_ALL;
                end
                ST_SYS_RESET_ALL: begin
                    if (reset_finished) begin
                        stat <= ST_SYS_DRAW_OPTION;
                    end
                end
                ST_SYS_DRAW_OPTION: begin
                    if (draw_option_finished) begin
                        stat <= ST_SYS_REFRESH_OPTION_SELECTION;
                    end
                end
                ST_SYS_OPTION_SELECTION: begin
                    if (option_select_changed) begin
                        stat <= ST_SYS_REFRESH_OPTION_SELECTION;
                    end
                    if (option_select_confirmed) begin
                        stat <= ST_SYS_DRAW_BACKGROUND;
                    end
                end
                ST_SYS_REFRESH_OPTION_SELECTION: begin
                    if (refresh_option_selection_finished) begin
                        stat <= ST_SYS_OPTION_SELECTION;
                    end
                end
                ST_SYS_DRAW_BACKGROUND: begin
                    if (reset_finished) begin
                        stat <= ST_SYS_DRAW_TOP_BAR;
                    end
                end
                ST_SYS_DRAW_TOP_BAR: begin
                    if (draw_top_bar_finished) begin
                        stat <= ST_SYS_INPUT_CHOOSE_MODE;
                    end
                end
                ST_SYS_INPUT_CHOOSE_MODE: begin
                    case (calc_mode) 
                        2'b01: begin
                            stat <= ST_SYS_MODE1_INPUT;
                        end
                        default: begin
                        end
                    endcase
                end
                ST_SYS_MODE1_INPUT: begin
                    if (mode1_input_finish) begin
                        stat <= ST_SYS_MODE1_RESET;
                    end

                end
                ST_SYS_MODE1_RESET: begin
                    stat <= ST_SYS_MODE1_RUNNING;
                end

                ST_SYS_MODE1_RUNNING: begin
                    if (mode1_moved_or_scaled) begin
                        stat <= ST_SYS_MODE1_RESET;
                    end else if (mode1_calc_finish) begin
                        stat <= ST_SYS_MODE1_FINISH;
                    end
                end

                ST_SYS_MODE1_FINISH: begin
                    if (mode1_moved_or_scaled) begin
                        stat <= ST_SYS_MODE1_RESET;
                    end else if (mode1_exit) begin
                        stat <= ST_SYS_IDLE;
                    end
                end
                default: begin

                end
            endcase
        end

    end
endmodule

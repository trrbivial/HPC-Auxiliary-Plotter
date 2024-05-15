`timescale 1ns / 1ps

`include "complex.vh"

module system_status (
    input wire clk,
    input wire rst,
    input wire [1:0] calc_mode,
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
                    stat <= ST_SYS_INPUT_CHOOSE_MODE;
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

`timescale 1ns / 1ps

`include "complex.vh"

module keyboard_parser (
    input wire clk,
    input wire rst,
    input wire system_status_t sys_stat,
    input wire scancode_valid,
    input wire [7:0] scancode,

    output reg [2:0] index_to_draw,
    output reg option_select_changed,
    output reg option_select_confirmed,
    output wire cp_axis screen_offset,
    output wire float_axis screen_scalar
);
    initial begin
        index_to_draw = 'b10;
    end

    cp_axis screen_offset_reg;
    float_axis screen_scalar_reg;

    assign screen_offset = screen_offset_reg;
    assign screen_scalar = screen_scalar_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            screen_offset_reg <= {1'b1, {POS_1_5, NEG_0_5}};
            screen_scalar_reg <= {1'b1, TWO_HUNDRED_FL};
        end else begin
            if (sys_stat == ST_SYS_MODE1_RUNNING) begin
                // TEMPRARY
                case (index_to_draw) 
                    'b00: begin
                        screen_offset_reg <= {1'b1, 64'b0};
                        screen_scalar_reg <= {1'b1, ONE_THOUSAND_FL};
                    end
                    'b01: begin
                        screen_offset_reg <= {1'b1, 64'b0};
                        screen_scalar_reg <= {1'b1, FIVE_HUNDRED_FL};
                    end
                    'b10: begin
                        screen_offset_reg <= {1'b1, {POS_1_5, NEG_0_5}};
                        screen_scalar_reg <= {1'b1, TWO_HUNDRED_FL};
                    end
                endcase

                if (scancode_valid) begin
                    case (scancode)
                        // 'h'
                        8'h33: begin
                        end

                        // 'j'
                        8'h3B: begin
                        end

                        // 'k'
                        8'h42: begin
                        end

                        // 'l'
                        8'h4B: begin

                        end

                        // '-'
                        8'h4E: begin

                        end

                        // '+'
                        8'h55: begin

                        end

                        // 'q'
                        8'h15: begin
                        end
                        default: begin
                        end
                    endcase
                end

            
            end
        end
    end


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            index_to_draw <= 'b10;
            option_select_changed <= 0;
            option_select_confirmed <= 0;
        end else begin
            if (option_select_changed) begin
                option_select_changed <= 0;
            end
            if (option_select_confirmed) begin
                option_select_confirmed <= 0;
            end
            if (sys_stat == ST_SYS_OPTION_SELECTION) begin
                if (scancode_valid) begin
                    case (scancode)
                        // 'j'
                        8'h3B: begin
                            index_to_draw <= index_to_draw == OPTION_COUNT - 1 ? 0 : index_to_draw + 1;
                            option_select_changed <= 1;
                        end

                        // 'k'
                        8'h42: begin
                            index_to_draw <= index_to_draw == 0 ? OPTION_COUNT - 1 : index_to_draw - 1;
                            option_select_changed <= 1;
                        end

                        // '\enter'
                        8'h5A: begin
                            option_select_confirmed <= 1;
                        end
                        default: begin
                        end
                    endcase
                end
            end
        end
    end
endmodule

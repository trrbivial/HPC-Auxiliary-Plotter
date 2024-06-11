`timescale 1ns / 1ps

`include "complex.vh"

module coef_in_controller (
    input wire clk,
    input wire rst,
    input wire system_status_t sys_stat,
    input wire option_select_confirmed,
    input wire [2:0] index_to_draw,

    output wire coef_axis coef_in
);
    coef_axis coef;
    assign coef_in = coef;

    initial begin
        coef.valid = 0;
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            coef <= 0;
        end else begin
            if (option_select_confirmed) begin
                coef <= 0;
                case (index_to_draw)
                    'b00: begin
                        coef.spm.mode <= 0;
                        coef.spm.range <= PI;
                        coef.p_t1.a[6] <= {32'b0, 32'hBD000000}; // -1.0i / 32
                        coef.p_t1.a[5] <= 0;
                        coef.p_t1.a[4] <= {32'hBC800000, 32'b0}; // -0.5 / 32
                        coef.p_t1.a[3] <= {32'h3C800000, 32'b0}; // +0.5 / 32
                        coef.p_t1.a[2] <= {32'hBC800000, 32'b0}; // -0.5 / 32
                        coef.p_t1.a[1] <= {32'b0, 32'h3D000000}; // +1.0i / 32
                        coef.p_t1.a[0] <= 0;
                        coef.ind_t1 <= 0;

                        coef.p_t2.a[6] <= {32'hBC800000, 32'b0}; // -0.5 / 32
                        coef.p_t2.a[5] <= {32'b0, 32'hBD000000}; // -1.0i / 32
                        coef.p_t2.a[4] <= {32'b0, 32'h3D000000}; // +1.0i / 32
                        coef.p_t2.a[3] <= 0;
                        coef.p_t2.a[2] <= {32'b0, 32'hBD000000}; // -1.0i / 32
                        coef.p_t2.a[1] <= {32'b0, 32'h3D000000}; // +1.0i / 32
                        coef.p_t2.a[0] <= 0;
                        coef.ind_t2 <= 5;

                        coef.p_c.a[6] <= ONE_CP;
                        coef.p_c.a[5] <= 0;
                        coef.p_c.a[4] <= {32'hBFC00000, 32'b0}; // -48.0 / 32
                        coef.p_c.a[3] <= 0;
                        coef.p_c.a[2] <= {32'h3F100000, 32'b0}; // +18.0 / 32
                        coef.p_c.a[1] <= 0;
                        coef.p_c.a[0] <= 0;
                    end
                    'b01: begin
                        coef.spm.mode <= 0;
                        coef.spm.range <= PI;
                        coef.p_t1.a[4] <= {32'h3E000000, 32'b0}; // +1.0 / 8
                        coef.p_t1.a[2] <= {32'h3E000000, 32'b0}; // +1.0 / 8
                        coef.p_t1.a[1] <= {32'b0, 32'hBE000000}; // -1.0i / 8
                        coef.p_t1.a[0] <= {32'hBE000000, 32'b0}; // -1.0 / 8
                        coef.ind_t1 <= 2;

                        coef.p_t2.a[4] <= {32'h3E000000, 32'b0}; // +1.0 / 8
                        coef.p_t2.a[2] <= {32'b0, 32'hBE000000}; // -1.0i / 8
                        coef.p_t2.a[0] <= {32'hBE000000, 32'b0}; // -1.0 / 8
                        coef.ind_t2 <= 4;

                        coef.p_c.a[6] <= ONE_CP;
                    end
                    'b10: begin
                        coef.spm.mode <= 1;
                        coef.spm.range <= ONE_HUNDRED_FL;
                        coef.p_t1.a[1] <= {32'b0, `neg_fl(ONE_FL)};
                        coef.p_t1.a[0] <= ONE_CP; 
                        coef.ind_t1 <= 0;

                        coef.p_t2.a[1] <= ONE_CP;
                        coef.p_t2.a[0] <= {32'b0, ONE_FL};
                        coef.ind_t2 <= 5;

                        coef.p_c.a[6] <= ONE_CP;
                        coef.p_c.a[5] <= 0;
                        coef.p_c.a[4] <= {32'b0, `neg_fl(ONE_FL)};
                        coef.p_c.a[3] <= ONE_CP;
                        coef.p_c.a[2] <= {32'b0, `neg_fl(ONE_FL)};
                        coef.p_c.a[1] <= 0;
                        coef.p_c.a[0] <= 0;
                    end
                    'b11: begin
                        coef.spm.mode <= 0;
                        coef.spm.range <= PI;
                        coef.p_t1.a[5] <= ONE_CP;
                        coef.p_t1.a[3] <= ONE_CP;
                        coef.p_t1.a[1] <= ONE_CP;
                        coef.ind_t1 <= 1;

                        coef.p_t2.a[1] <= ONE_CP;
                        coef.ind_t2 <= 5;

                        coef.p_c.a[6] <= ONE_CP;
                    end
                    'b100: begin
                        coef.spm.mode <= 0;
                        coef.spm.range <= PI;
                        coef.p_t1.a[1] <= {TWO_FL, 32'b0};
                        coef.ind_t1 <= 3;

                        coef.p_t2.a[1] <= ONE_CP;
                        coef.ind_t2 <= 5;

                        coef.p_c.a[6] <= ONE_CP;
                    end
                    default: begin

                    end
                endcase
            end
            coef.valid <= 0;
            if (sys_stat == ST_SYS_MODE1_RUNNING) begin
                coef.valid <= 1;
            end
        end

    end
    
endmodule

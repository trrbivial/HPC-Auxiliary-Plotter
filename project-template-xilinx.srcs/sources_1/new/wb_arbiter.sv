`timescale 1ns / 1ps

`include "complex.vh"

module wb_arbiter #(
    MASTER_COUNT = GM_MASTER_COUNT
) (
    input wire clk,
    input wire rst,

    input wire wbm_signal_send wbm_i[MASTER_COUNT - 1:0],
    output wire wbm_signal_recv wbm_o[MASTER_COUNT - 1:0],

    input wire wbm_signal_recv wbs_i,
    output wire wbm_signal_send wbs_o
);

    localparam MASTER_WIDTH = $clog2(MASTER_COUNT);

    logic [MASTER_WIDTH - 1:0] current_master, highest_master;
    wbm_signal_recv wbm_o_reg[MASTER_COUNT - 1:0];
    wbm_signal_send wbs_o_reg;

    assign wbm_o = wbm_o_reg;
    assign wbs_o = wbs_o_reg;

    always_comb begin
        for (integer i = 0; i < MASTER_COUNT; ++i) begin
            wbm_o_reg[i] = 0;
        end

        wbm_o_reg[current_master] = wbs_i;
        wbs_o_reg = wbm_i[current_master];

        highest_master = 0;
        for (integer i = MASTER_COUNT - 1; i >= 0; --i) begin
            if (wbm_i[i].cyc && wbm_i[i].stb) highest_master = i;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_master <= 0;
        end else begin 
            if (!wbs_o.cyc) begin
                current_master <= highest_master;
            end
        end
    end

endmodule


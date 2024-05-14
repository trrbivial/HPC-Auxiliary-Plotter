`timescale 1ns / 1ps

`include "complex.vh"


module iteration # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire mat_axis in,
    output wire roots_axis out
);
    iteration_status_t stat;
    logic batch_from_input;
    logic output_from_batch;
    logic [15:0] cnt_cycs;
    logic [15:0] iter_times;
    roots_axis out_reg;

    mat_axis qr_decomp_in;
    qr_axis qr_decomp_out;

    qr_decomp m_qr_decomp (clk, rst, qr_decomp_in, qr_decomp_out);

    always_comb begin
        output_from_batch = 
            (stat == ST_ITER_IN_BATCH && iter_times == ITER_TIMES && cnt_cycs == QR_DECOMP_CYCS) | 
            (stat == ST_ITER_FIN);
        batch_from_input = 
            (stat == ST_ITER_INIT && in.valid) | 
            (stat == ST_ITER_IN_BATCH && iter_times == 1 && cnt_cycs < QR_DECOMP_CYCS);

        if (batch_from_input) begin
            qr_decomp_in = in;
        end else begin
            qr_decomp_in = {qr_decomp_out.valid, qr_decomp_out.meta.a};
        end

        if (output_from_batch) begin
            out_reg.valid = qr_decomp_out.valid;
            for (int i = 0; i < MAX_N; i = i + 1) begin
                out_reg.meta.x[i] = qr_decomp_out.meta.a.r[i].c[i];
            end
        end else begin
            out_reg.valid = 0;
        end
    end

    assign out = out_reg;
    
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            stat <= ST_ITER_INIT;
        end else begin
            case (stat)
                ST_ITER_INIT: begin
                    if (in.valid) begin
                        stat <= ST_ITER_IN_BATCH;
                        cnt_cycs <= 1;
                        iter_times <= 1;
                    end
                end
                ST_ITER_IN_BATCH: begin
                    if (cnt_cycs == QR_DECOMP_CYCS) begin
                        cnt_cycs <= 1;
                        if (iter_times == ITER_TIMES) begin
                            stat <= ST_ITER_FIN;
                        end
                        iter_times <= iter_times + 1;
                    end else begin
                        cnt_cycs <= cnt_cycs + 1;
                    end
                end
                ST_ITER_FIN: begin
                    if (cnt_cycs == QR_DECOMP_CYCS) begin
                        stat <= ST_ITER_INIT;
                    end else begin
                        cnt_cycs <= cnt_cycs + 1;
                    end
                end
                default: begin
                end
            endcase
        end
    end


endmodule

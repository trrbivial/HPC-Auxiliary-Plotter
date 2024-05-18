`timescale 1ns / 1ps

`include "complex.vh"

module generate_poly # (
    parameter MAX_N = MAX_DEG
) (
    input wire clk,
    input wire rst,
    input wire coef_axis in,
    input wire iter_in_ready,
    output wire poly_axis out
);
    cp_axis t1, t2;
    logic pipe_running;
    logic pipe_clk;

    assign pipe_clk = clk & pipe_running;

    always_ff @(negedge clk, posedge rst) begin
        if (rst) begin
            pipe_running <= 1;
        end else begin
            pipe_running <= iter_in_ready;
        end
    end
    sampling_coefs m_sampling_coefs (
        .clk(pipe_clk),
        .rst(rst),
        .spm({in.valid, in.spm}),
        .t1(t1),
        .t2(t2)
    );

    cp_axis c1, c2;
    poly_value poly_value_t1 (
        .clk(pipe_clk),
        .rst(rst),
        .p({in.valid, in.p_t1}), 
        .x(t1),
        .y(c1)
    );
    poly_value poly_value_t2 (
        .clk(pipe_clk),
        .rst(rst),
        .p({in.valid, in.p_t2}),
        .x(t2),
        .y(c2)
    );

    poly_axis out_reg;

    assign out = out_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_reg <= 0;
        end else begin
            if (iter_in_ready) begin
                out_reg.valid <= c1.valid & c2.valid;
                out_reg.meta.a <= in.p_c;
                out_reg.meta.a[in.ind_t1] <= c1.meta;
                out_reg.meta.a[in.ind_t2] <= c2.meta;
            end
        end
    end
    /*

    logic [DATA_WIDTH - 1:0] offset;
    always_comb begin
        offset = 0;
        offset[31] = 1'b1;
        for (int i = 0; i <= MAX_DEG; i = i + 1) begin
            if (g.meta.a[i] != 0) begin
                offset = MAX_DEG - i;
            end
        end
    end

    cp_axis tmp4[MAX_DEG:0], tmp5[MAX_DEG:0];

    assign tmp4[MAX_DEG].valid = g.valid;
    assign tmp4[MAX_DEG].meta = 
        offset[31] ? ONE_CP :
        g.meta.a[MAX_DEG - offset];
    assign tmp5[MAX_DEG] = {1'b1, ONE_CP};

    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            assign tmp4[i].valid = g.valid;
            assign tmp4[i].meta = 
                (offset[31] | (i - offset < 0)) ? 64'b0 :
                g.meta.a[i - offset];

            complex_diver cp_div_i (
                clk, tmp4[i], tmp4[MAX_DEG], tmp5[i]
            );
        end
    endgenerate

    always_comb begin
        valid = 1;
        for (int i = 0; i <= MAX_DEG; i = i + 1) begin
            valid &= tmp5[i].valid;
        end
    end

    logic write_poly_ready;
    axis_data_fifo_poly m_axis_data_fifo_poly (
        .s_axis_aclk(clk),
        .s_axis_aresetn(~rst),
        .s_axis_tvalid(f.valid),
        .s_axis_tdata(f.meta),
        .m_axis_tready(iter_in_ready),

        .s_axis_tready(write_poly_ready),
        .m_axis_tvalid(out.valid),
        .m_axis_tdata(out.meta)
    );
    */
endmodule

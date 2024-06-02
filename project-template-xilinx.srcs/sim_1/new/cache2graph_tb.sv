`timescale 1ns / 1ps

`include "complex.vh"

module cache2graph_tb();

    reg clk;
    reg rst;

    roots roots_r1;
    roots roots_r2;
    logic valid;
    logic r1;
    cp_axis offset;
    float_axis scalar;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, cache2graph_tb);
        clk = 1'b0;
        rst = 1'b0;
        valid = 0;
        r1 = 1'b0;
        roots_r1.x[0] = {32'h3F800000, 32'h40C00000};
        roots_r1.x[1] = {32'h40000000, 32'h40A00000};
        roots_r1.x[2] = {32'h40400000, 32'h40800000};
        roots_r1.x[3] = {32'h40800000, 32'h40400000};
        roots_r1.x[4] = {32'h40A00000, 32'h40000000};
        roots_r1.x[5] = {32'h40C00000, 32'h3F800000};
        roots_r2.x[0] = {32'h3F800000, 32'h0};
        roots_r2.x[1] = {32'h40000000, 32'h0};
        roots_r2.x[2] = {32'h40400000, 32'h0};
        roots_r2.x[3] = {32'h40800000, 32'h0};
        roots_r2.x[4] = {32'h40A00000, 32'h0};
        roots_r2.x[5] = {32'h40C00000, 32'h0};
        offset = {1'b1, {NEG_0_5, NEG_0_5}};
        scalar = {1'b1, ONE_HUNDRED_FL};

        #100;
        rst = 1'b1;

        #100;
        rst = 1'b0;

        #102;
        valid = 1;

        #7000;
        valid = 0;

        #500000;
        $finish;
    end

    always #5 clk = ~clk; // 100MHz
    always #10 r1 = ~r1;

    roots_axis roots_out;
    assign roots_out.valid = valid;
    assign roots_out.meta = r1 ? roots_r1 : roots_r2;

    pixels_axis pixels_out;

    roots2pixels m_roots2pixels (
        .clk(clk),
        .rst(rst),
        .in(roots_out),
        .offset(offset),
        .scalar(scalar),

        .out(pixels_out)
    );

    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_a_addr;
    logic bram_we;
    logic [CP_DATA_WIDTH - 1:0] bram_a_data[MAX_DEG - 1:0];

    logic [2:0] index;
    logic [BRAM_1024_ADDR_WIDTH - 1:0] bram_b_addr[MAX_DEG - 1:0];
    logic [CP_DATA_WIDTH - 1:0] bram_b_data[MAX_DEG - 1:0];

    pixels2bram m_pixels2bram (
        .clk(clk),
        .rst(rst),
        .in(pixels_out),
        .bram_addr(bram_a_addr),
        .bram_we(bram_we),
        .bram_data(bram_a_data)
    );

    genvar i;
    generate
        for (i = 0; i < MAX_DEG; i = i + 1) begin
            bram_of_1024_complex bram_i (
                .clka(clk),
                .addra(bram_a_addr),
                .dina(bram_a_data[i]),
                .wea(bram_we),

                .clkb(clk),
                .addrb(bram_b_addr[i]),
                .doutb(bram_b_data[i])
            );
        end
    endgenerate

    logic graph_memory_a_we;
    logic [BRAM_524288_ADDR_WIDTH - 1:0] graph_memory_a_addr;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_a_in_data;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_a_out_data;

    logic clk_b;
    logic [BRAM_524288_ADDR_WIDTH - 1:0] graph_memory_b_addr;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] graph_memory_b_data;

    cache2graph m_cache2graph (
        .clk(clk),
        .rst(rst),
        .rear(bram_a_addr),
        .bram_data(bram_b_data[index]),
        .graph_memory_a_out_data(graph_memory_a_out_data),

        .bram_addr(bram_b_addr),
        .ind(index),
        .graph_memory_a_addr(graph_memory_a_addr),
        .graph_memory_a_in_data(graph_memory_a_in_data),
        .graph_memory_a_we(graph_memory_a_we)
    );

    assign clk_b = clk;

    bram_of_1080p_graph graph_memory (
        .clka(clk),
        .addra(graph_memory_a_addr),
        .dina(graph_memory_a_in_data),
        .douta(graph_memory_a_out_data),
        .wea(graph_memory_a_we),

        .clkb(clk_b),
        .addrb(graph_memory_b_addr),
        .dinb(16'b0),
        .doutb(graph_memory_b_data),
        .web(1'b0)
    );

endmodule


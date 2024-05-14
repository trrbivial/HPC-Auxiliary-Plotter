`timescale 1ns / 1ps

`include "complex.vh"

module mod_top(
    // 时钟
    input  wire clk_100m,           // 100M 输入时钟

    // 开关
    input  wire btn_clk,            // 左侧微动开关（CLK），推荐作为手动时钟，带消抖电路，按下时为 1
    input  wire btn_rst,            // 右侧微动开关（RST），推荐作为手动复位，带消抖电路，按下时为 1
    input  wire [3:0]  btn_push,    // 四个按钮开关（KEY1-4），按下时为 1
    input  wire [15:0] dip_sw,      // 16 位拨码开关，拨到 “ON” 时为 0

    // 32 位 LED 灯，配合 led_scan 模块使用
    output wire [7:0] led_bit,      // 8 位 LED 信号
    output wire [3:0] led_com,      // LED 扫描信号，每一位对应 8 位的 LED 信号

    // 数码管，配合 dpy_scan 模块使用
    output wire [7:0] dpy_digit,   // 七段数码管笔段信号
    output wire [7:0] dpy_segment, // 七段数码管位扫描信号

    // 以下是一些被注释掉的外设接口
    // 若要使用，不要忘记去掉 io.xdc 中对应行的注释

    // PS/2 键盘
    // input  wire        ps2_keyboard_clk,     // PS/2 键盘时钟信号
    // input  wire        ps2_keyboard_data,    // PS/2 键盘数据信号

    // PS/2 鼠标
    // inout  wire       ps2_mouse_clk,     // PS/2 时钟信号
    // inout  wire       ps2_mouse_data,    // PS/2 数据信号

    // SD 卡（SPI 模式）
    // output wire        sd_sclk,     // SPI 时钟
    // output wire        sd_mosi,     // 数据输出
    // input  wire        sd_miso,     // 数据输入
    // output wire        sd_cs,       // SPI 片选，低有效
    // input  wire        sd_cd,       // 卡插入检测，0 表示有卡插入
    // input  wire        sd_wp,       // 写保护检测，0 表示写保护状态

    // RGMII 以太网接口
    // output wire        rgmii_clk125,
    // input  wire        rgmii_rx_clk,
    // input  wire        rgmii_rx_ctl,
    // input  wire [3: 0] rgmii_rx_data,
    // output wire        rgmii_tx_clk,
    // output wire        rgmii_tx_ctl,
    // output wire [3: 0] rgmii_tx_data,

    // 4MB SRAM 内存
    // inout  wire [31:0] base_ram_data,   // SRAM 数据
    // output wire [19:0] base_ram_addr,   // SRAM 地址
    // output wire [3: 0] base_ram_be_n,   // SRAM 字节使能，低有效。如果不使用字节使能，请保持为0
    // output wire        base_ram_ce_n,   // SRAM 片选，低有效
    // output wire        base_ram_oe_n,   // SRAM 读使能，低有效
    // output wire        base_ram_we_n,   // SRAM 写使能，低有效

    // HDMI 图像输出
    output wire [2:0] hdmi_tmds_n,    // HDMI TMDS 数据信号
    output wire [2:0] hdmi_tmds_p,    // HDMI TMDS 数据信号
    output wire       hdmi_tmds_c_n,  // HDMI TMDS 时钟信号
    output wire       hdmi_tmds_c_p   // HDMI TMDS 时钟信号

    );

    // 使用 100MHz 时钟作为后续逻辑的时钟
    wire clk_in = clk_100m;

    // PLL 分频演示，从输入产生不同频率的时钟
    wire clk_hdmi;
    wire clk_locked;
    ip_pll u_ip_pll(
        .clk_in1  (clk_in    ),  // 输入 100MHz 时钟
        .reset    (btn_rst   ),  // 复位信号，高有效
        .clk_out1 (clk_hdmi  ),  // 74.250MHz 像素时钟
        .locked   (clk_locked)   // 高表示 74.250MHz 时钟已经稳定输出
    );
    logic clk, rst;
    assign clk = clk_in;
    assign rst = btn_rst;

    // 七段数码管扫描演示
    reg [31:0] number;
    dpy_scan u_dpy_scan (
        .clk     (clk_in      ),
        .number  (number      ),
        .dp      (8'b0        ),

        .digit   (dpy_digit   ),
        .segment (dpy_segment )
    );

    // 自增计数器，用于数码管演示
    reg [31:0] counter;
    always @(posedge clk_in) begin
        if (btn_rst) begin
            counter <= 32'b0;
            number <= 32'b0;
        end else begin
            counter <= counter + 32'b1;
            if (counter == 32'd5_000_000) begin
                counter <= 32'b0;
                number <= number + 32'b1;
            end
        end
    end

    // LED 演示
    wire [31:0] leds;
    assign leds[15:0] = number[15:0];
    assign leds[31:16] = ~(dip_sw) ^ btn_push;
    led_scan u_led_scan (
        .clk     (clk_in      ),
        .leds    (leds        ),

        .led_bit (led_bit     ),
        .led_com (led_com     )
    );




    // 图像输出演示，分辨率 800x600@72Hz，像素时钟为 50MHz，显示渐变色彩条
    wire [11:0] hdata;  // 当前横坐标
    wire [11:0] vdata;  // 当前纵坐标
    wire [7:0] video_red; // 红色分量
    wire [7:0] video_green; // 绿色分量
    wire [7:0] video_blue; // 蓝色分量
    wire video_clk; // 像素时钟
    wire video_hsync;
    wire video_vsync;

    // 生成彩条数据，分别取坐标低位作为 RGB 值
    // 警告：该图像生成方式仅供演示，请勿使用横纵坐标驱动大量逻辑！！
    assign video_red = vdata < 200 ? hdata[8:1] : 8'b0;
    assign video_green = vdata >= 200 && vdata < 400 ? hdata[8:1] : 8'b0;
    assign video_blue = vdata >= 400 ? hdata[8:1] : 8'b0;

    assign video_clk = clk_hdmi;

    video #(16, VGA_HSIZE, VGA_HFP, VGA_HSP, VGA_HMAX, VGA_VSIZE, VGA_VFP, VGA_VSP, VGA_VMAX, 1, 1) u_video1080p30hz (
        .clk(video_clk), 
        .hdata(hdata), //横坐标
        .vdata(vdata), //纵坐标
        .hsync(video_hsync),
        .vsync(video_vsync),
        .data_enable(video_de)
    );

    // 把 RGB 转化为 HDMI TMDS 信号并输出
    ip_rgb2dvi u_ip_rgb2dvi (
        .PixelClk   (video_clk),
        .vid_pVDE   (video_de),
        .vid_pHSync (video_hsync),
        .vid_pVSync (video_vsync),
        .vid_pData  ({video_red, video_blue, video_green}),
        .aRst       (~clk_locked),

        .TMDS_Clk_p  (hdmi_tmds_c_p),
        .TMDS_Clk_n  (hdmi_tmds_c_n),
        .TMDS_Data_p (hdmi_tmds_p),
        .TMDS_Data_n (hdmi_tmds_n)
    );

    mat mat_identity;
    mat mat_r1;
    mat mat_r2;
    logic mat_valid;
    logic r1;
    always_comb begin
        for (integer i = 0; i < MAX_DEG; i = i + 1) begin
            for (integer j = 0; j < MAX_DEG; j = j + 1) begin
                mat_identity.r[i].c[j] = (i == j) ? ONE_CP : 0;
                mat_r1.r[i].c[j] = (i == j + 1) ? ONE_CP : 0;
                mat_r2.r[i].c[j] = (i == j + 1) ? ONE_CP : 0;
            end
        end
        mat_r1.r[0].c[0] = {32'h3F800000, 32'h40C00000};
        mat_r1.r[0].c[1] = {32'h40000000, 32'h40A00000};
        mat_r1.r[0].c[2] = {32'h40400000, 32'h40800000};
        mat_r1.r[0].c[3] = {32'h40800000, 32'h40400000};
        mat_r1.r[0].c[4] = {32'h40A00000, 32'h40000000};
        mat_r1.r[0].c[5] = {32'h40C00000, 32'h3F800000};
        mat_r2.r[0].c[0] = {32'h3F800000, 32'h0};
        mat_r2.r[0].c[1] = {32'h40000000, 32'h0};
        mat_r2.r[0].c[2] = {32'h40400000, 32'h0};
        mat_r2.r[0].c[3] = {32'h40800000, 32'h0};
        mat_r2.r[0].c[4] = {32'h40A00000, 32'h0};
        mat_r2.r[0].c[5] = {32'h40C00000, 32'h0};
    end

    logic rsted;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            r1 <= 0;
            mat_valid <= 0;
            rsted <= 1;
        end else begin
            r1 <= r1 ^ 1'b1;
            if (rsted) mat_valid <= 1;
        end
    end

    mat_axis mat_in;
    roots_axis roots_out;
    pixels_axis pixels_out;
    assign mat_in.valid = mat_valid;
    assign mat_in.meta = r1 ? mat_r1 : mat_r2;

    cp_axis screen_offset;
    float_axis screen_scalar;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            screen_offset <= {1'b1, {NEG_0_5, NEG_0_5}};
            screen_scalar <= {1'b1, ONE_HUNDRED_FL};
        end else begin

        end
    end


    iteration m_iterations (
        .clk(clk),
        .rst(rst),
        .in(mat_in),
        .out(roots_out)
    );
    roots2pixels m_roots2pixels (
        .clk(clk),
        .rst(rst),
        .in(roots_out),
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

    assign clk_b = video_clk;

    bram_of_1080p_graph graph_memory (
        .clka(clk),
        .addra(graph_memory_a_addr),
        .dina(graph_memory_a_in_data),
        .douta(graph_memory_a_out_data),
        .wea(graph_memory_a_we),

        .clkb(clk_b),
        .addrb(graph_memory_b_addr),
        .doutb(graph_memory_b_data)
    );



endmodule

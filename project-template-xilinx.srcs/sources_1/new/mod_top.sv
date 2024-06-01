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
    input  wire        ps2_keyboard_clk,     // PS/2 键盘时钟信号
    input  wire        ps2_keyboard_data,    // PS/2 键盘数据信号

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
    inout  wire [31:0] base_ram_data,   // SRAM 数据
    output wire [19:0] base_ram_addr,   // SRAM 地址
    output wire [3: 0] base_ram_be_n,   // SRAM 字节使能，低有效。如果不使用字节使能，请保持为0
    output wire        base_ram_ce_n,   // SRAM 片选，低有效
    output wire        base_ram_oe_n,   // SRAM 读使能，低有效
    output wire        base_ram_we_n,   // SRAM 写使能，低有效

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
        .clk_out1 (clk_hdmi  ),  // 148.500MHz 像素时钟
        .locked   (clk_locked)   // 高表示 hdmi 时钟已经稳定输出
    );
    logic clk, rst;
    assign clk = clk_in;
    assign rst = btn_rst;

    // 在数码管上显示 PS/2 Keyboard scancode
    wire [7:0] scancode;
    wire scancode_valid;
    ps2_keyboard u_ps2_keyboard (
        .clock     (clk_in           ),
        .reset     (btn_rst          ),
        .ps2_clock (ps2_keyboard_clk ),
        .ps2_data  (ps2_keyboard_data),
        .scancode  (scancode         ),
        .valid     (scancode_valid   )
    );

    // 七段数码管扫描演示
    reg [31:0] number;
    dpy_scan u_dpy_scan (
        .clk     (clk_hdmi),
        .number  (number),
        .dp      (8'b0),

        .digit   (dpy_digit),
        .segment (dpy_segment)
    );
    always @(posedge clk_in) begin
        if (btn_rst) begin
            number <= 32'b0;
        end else begin
            if (scancode_valid) begin
                number <= {number, scancode};
            end
        end
    end

    // LED 演示
    wire [31:0] leds;
    assign leds[15:0] = number[15:0];
    assign leds[31:16] = ~(dip_sw) ^ btn_push;
    led_scan u_led_scan (
        .clk     (clk_hdmi),
        .leds    (leds),

        .led_bit (led_bit),
        .led_com (led_com)
    );

    logic reset_finished;

    logic draw_option_finished;

    logic option_select_changed;
    logic refresh_option_selection_finished;
    logic option_select_confirmed;

    logic draw_top_bar_finished;

    logic [2:0] index_to_draw;
    cp_axis screen_offset;
    float_axis screen_scalar;

    system_status_t sys_stat;
    system_status m_system_status (
        .clk(clk),
        .rst(rst),

        .calc_mode(2'b01),
        .reset_finished(reset_finished),
        .draw_option_finished(draw_option_finished),

        .option_select_changed(option_select_changed),
        .refresh_option_selection_finished(refresh_option_selection_finished),
        .option_select_confirmed(option_select_confirmed),

        .draw_top_bar_finished(draw_top_bar_finished),
        .mode1_input_finish(1'b1),
        .mode1_moved_or_scaled(1'b0),
        .mode1_calc_finish(1'b0),
        .mode1_exit(1'b0),

        .system_status(sys_stat)
    );

    keyboard_parser m_keyboard_parser (
        .clk(clk),
        .rst(rst),
        .sys_stat(sys_stat),
        .scancode_valid(scancode_valid),
        .scancode(scancode),

        .index_to_draw(index_to_draw),
        .option_select_changed(option_select_changed),
        .option_select_confirmed(option_select_confirmed),
        .screen_offset(screen_offset),
        .screen_scalar(screen_scalar)
    );


    coef_axis coef_in;
    poly_axis poly_in;
    mat_axis mat_in;
    roots_axis roots_out;
    logic iter_in_ready;

    coef_in_controller m_coef_in_controller (
        .clk(clk),
        .rst(rst),
        .sys_stat(sys_stat),
        .index_to_draw(index_to_draw),
        .option_select_confirmed(option_select_confirmed),

        .coef_in(coef_in)
    );

    generate_poly m_gen_poly (
        .clk(clk),
        .rst(rst),
        .in(coef_in),
        .iter_in_ready(iter_in_ready),

        .out(poly_in)
    );

    poly2mat m_poly2mat (
        .clk(clk),
        .rst(rst),
        .in(poly_in),
        .out(mat_in)
    );

    qr_decomp m_qr_decomp_iter (
        .clk(clk),
        .rst(rst),
        .in(mat_in),

        .out(roots_out),
        .in_ready(iter_in_ready)
    );

    pixels_axis pixels_out;

    roots2pixels m_roots2pixels (
        .clk(clk),
        .rst(rst),
        .in(roots_out),
        .offset(screen_offset),
        .scalar(screen_scalar),

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

    wbm_signal_send wbm_o[GM_MASTER_COUNT - 1:0];
    wbm_signal_recv wbm_i[GM_MASTER_COUNT - 1:0];

    wbm_signal_send wbs_i;
    wbm_signal_recv wbs_o;

    logic [1:0] count_ack;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            wbs_o.ack <= 0;
            count_ack <= 0;
        end else begin
            if (wbs_i.cyc && wbs_i.stb) begin
                if (wbs_i.we) begin
                    wbs_o.ack <= 1;
                end else begin
                    count_ack <= count_ack + 1;
                    if (count_ack == 2) begin
                        wbs_o.ack <= 1;
                    end
                end
            end
            if (wbs_o.ack) begin
                wbs_o.ack <= 0;
                count_ack <= 0;
            end
        end
    end

    wb_arbiter wb_arbiter_i (
        .clk(clk),
        .rst(rst),

        .wbm_i(wbm_o),
        .wbm_o(wbm_i),

        .wbs_i(wbs_o),
        .wbs_o(wbs_i)
    );

    cache2graph m_cache2graph (
        .clk(clk),
        .rst(rst),
        .rear(bram_a_addr),
        .bram_data(bram_b_data[index]),
        .wbm_i(wbm_i[0]),

        .bram_addr(bram_b_addr),
        .ind(index),
        .wbm_o(wbm_o[0])
    );

    reset_all rst_all (
        .clk(clk),
        .rst(rst),
        .sys_stat(sys_stat),
        .wbm_i(wbm_i[1]),

        .wbm_o(wbm_o[1]),
        .reset_finished(reset_finished)
    );

    sram_signal_recv sram_wbm_i;
    sram_signal_send sram_wbm_o;

    draw_top_bar m_draw_top_bar (
        .clk(clk),
        .rst(rst),
        .sys_stat(sys_stat),
        .index(index_to_draw),
        .wbm_i(wbm_i[2]),
        .sram_wbm_i(sram_wbm_i),

        .wbm_o(wbm_o[2]),
        .sram_wbm_o(sram_wbm_o),
        .draw_top_bar_finished(draw_top_bar_finished),
        .draw_option_finished(draw_option_finished),
        .refresh_option_selection_finished(refresh_option_selection_finished)
    );

    sram_controller m_sram_controller (
        .clk(clk),
        .rst(rst),
        .wbs_i(sram_wbm_o),
        .wbs_o(sram_wbm_i),
        .sram_addr(base_ram_addr),
        .sram_data(base_ram_data),
        .sram_ce_n(base_ram_ce_n),
        .sram_oe_n(base_ram_oe_n),
        .sram_we_n(base_ram_we_n),
        .sram_be_n(base_ram_be_n)
    );

    // 图像输出，分辨率 1920x1080@60Hz，像素时钟为 148.500MHz
    wire [11:0] hdata;  // 当前横坐标
    wire [11:0] vdata;  // 当前纵坐标

    wire [3:0] video_gray4; // 像素
    wire [7:0] video_gray8; // 灰度

    wire video_clk;     // 像素时钟
    wire video_hsync;   // 行同步信号
    wire video_vsync;   // 场同步信号
    logic video_de;

    wire [7:0] video_red; // 红色分量
    wire [7:0] video_green; // 绿色分量
    wire [7:0] video_blue; // 蓝色分量

    assign video_clk = clk_hdmi;

    video #(12, VGA_HSIZE, VGA_HFP, VGA_HSP, VGA_HMAX, VGA_VSIZE, VGA_VFP, VGA_VSP, VGA_VMAX, 1, 1) u_video1080p60hz (
        .clk(video_clk), 
        .hdata(hdata), //横坐标
        .vdata(vdata), //纵坐标
        .hsync(video_hsync),
        .vsync(video_vsync),
        .data_enable(video_de)
    );

    // 遍历 BRAM 地址，以得到存放的像素点
    // 注意根据 横坐标、纵坐标 预读取数据，以保证同步信号
    logic gm_clk_b;
    logic gm_enb;
    logic [$clog2(BRAM_GRAPH_MEM_DEPTH) - 1:0] gm_addrb;
    packed_pixel_data gm_datab;
    assign gm_clk_b = video_clk;

    travel_forward #(12, VGA_HSIZE, VGA_HMAX, VGA_VSIZE, VGA_VMAX) m_travel_forward (
        .clk(video_clk),
        .hdata(hdata),
        .vdata(vdata),
        .data_enable(video_de),
        .data(gm_datab),

        .addr(gm_addrb),
        .enb(gm_enb),
        .pixel(video_gray8)
    );

    // 把 RGB 转化为 HDMI TMDS 信号并输出
    ip_rgb2dvi u_ip_rgb2dvi (
        .PixelClk   (video_clk),
        .vid_pVDE   (video_de),
        .vid_pHSync (video_hsync),
        .vid_pVSync (video_vsync),
        .vid_pData  (video_de ? {8'd255 ^ video_gray8, 8'd255 ^ video_gray8, 8'd255 ^ video_gray8} : 'b0),
        .aRst       (~clk_locked),

        .TMDS_Clk_p  (hdmi_tmds_c_p),
        .TMDS_Clk_n  (hdmi_tmds_c_n),
        .TMDS_Data_p (hdmi_tmds_p),
        .TMDS_Data_n (hdmi_tmds_n)
    );

    bram_of_1080p_graph graph_memory (
        .clka(clk),
        .addra(wbs_i.adr),
        .dina(wbs_i.dat),
        .douta(wbs_o.dat),
        .wea(wbs_i.we),

        .clkb(gm_clk_b),
        .addrb(gm_addrb),
        .enb(gm_enb),
        .dinb('b0),
        .doutb(gm_datab),
        .web(1'b0)
    );


endmodule

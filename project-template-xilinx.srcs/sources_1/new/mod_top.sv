`timescale 1ns / 1ps
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
    wire clk_hdmi_locked;
    ip_pll u_ip_pll(
        .clk_in1  (clk_in         ),  // 输入 100MHz 时钟
        .reset    (btn_rst        ),  // 复位信号，高有效
        .clk_out1 (clk_hdmi       ),  // 50MHz 像素时钟
        .locked   (clk_hdmi_locked)   // 高表示 50MHz 时钟已经稳定输出
    );

    // 七段数码管扫描演示
    reg [31:0] number;
    dpy_scan u_dpy_scan (
        .clk     (clk_in      ),
        .number  (number      ),
        .dp      (7'b0        ),

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
    video #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) u_video800x600at72 (
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
        .aRst       (~clk_hdmi_locked),

        .TMDS_Clk_p  (hdmi_tmds_c_p),
        .TMDS_Clk_n  (hdmi_tmds_c_n),
        .TMDS_Data_p (hdmi_tmds_p),
        .TMDS_Data_n (hdmi_tmds_n)
    );

endmodule

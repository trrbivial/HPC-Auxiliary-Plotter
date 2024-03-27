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
    output wire [7:0] dpy_segment  // 七段数码管位扫描信号

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

endmodule

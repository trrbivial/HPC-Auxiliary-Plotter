`timescale 1ns / 1ps

`include "complex.vh"

// 6 cycles late from posedge to posedge
module complex2pixel (
    input wire clk,
    input wire cp_axis in,
    output wire pixel_axis out
);

    logic v1, v2;
    floating_to_integer_0 fl2int_1 (
        .aclk(clk), 
        .s_axis_a_tvalid(in.valid),
        .s_axis_a_tdata(in.meta.r),
        .m_axis_result_tvalid(v1),
        .m_axis_result_tdata(out.meta.x)
    );
    floating_to_integer_0 fl2int_2 (
        .aclk(clk), 
        .s_axis_a_tvalid(in.valid),
        .s_axis_a_tdata(in.meta.i),
        .m_axis_result_tvalid(v2),
        .m_axis_result_tdata(out.meta.y)
    );
    assign out.valid = v1 & v2;
endmodule


// 11 cycles late from posedge to posedge
module complex_suber (
    input wire clk,
    input wire cp_axis a,
    input wire cp_axis b,
    output wire cp_axis c
);
    cp ma, mb;
    assign ma = a.meta;
    assign mb = b.meta;

    logic add_r_valid;
    logic add_i_valid;

    floating_sub_0 floating_sub_m0 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c.meta.r),
        .m_axis_result_tvalid(add_r_valid)
    );

    floating_sub_0 floating_sub_m1 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c.meta.i),
        .m_axis_result_tvalid(add_i_valid)
    );

    assign c.valid = add_r_valid & add_i_valid;
endmodule

// 11 cycles late from posedge to posedge
module complex_adder (
    input wire clk,
    input wire cp_axis a,
    input wire cp_axis b,
    output wire cp_axis c
);
    cp ma, mb;
    assign ma = a.meta;
    assign mb = b.meta;

    logic add_r_valid;
    logic add_i_valid;

    floating_add_0 floating_add_m0 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c.meta.r),
        .m_axis_result_tvalid(add_r_valid)
    );

    floating_add_0 floating_add_m1 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c.meta.i),
        .m_axis_result_tvalid(add_i_valid)
    );

    assign c.valid = add_r_valid & add_i_valid;
endmodule


// 17 cycles late from posedge to posedge
module complex_multiplier #(
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire cp_axis a,
    input wire cp_axis b,
    output wire cp_axis c
);
    cp ma, mb;
    assign ma = a.meta;
    assign mb = b.meta;

    float_axis c0, c1, c2, c3;
    floating_mul_0 floating_mul_m0 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c0.meta),
        .m_axis_result_tvalid(c0.valid)
    );

    floating_mul_0 floating_mul_m1 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c1.meta),
        .m_axis_result_tvalid(c1.valid)
    );

    floating_mul_0 floating_mul_m2 (
        .aclk(clk),
        .s_axis_a_tdata(ma.r),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.i),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c2.meta),
        .m_axis_result_tvalid(c2.valid)
    );

    floating_mul_0 floating_mul_m3 (
        .aclk(clk),
        .s_axis_a_tdata(ma.i),
        .s_axis_a_tvalid(a.valid),
        .s_axis_b_tdata(mb.r),
        .s_axis_b_tvalid(b.valid),
        .m_axis_result_tdata(c3.meta),
        .m_axis_result_tvalid(c3.valid)
    );

    logic sub_valid;
    logic add_valid;

    floating_sub_0 floating_sub_m0 (
        .aclk(clk),
        .s_axis_a_tdata(c0.meta),
        .s_axis_a_tvalid(c0.valid),
        .s_axis_b_tdata(c1.meta),
        .s_axis_b_tvalid(c1.valid),
        .m_axis_result_tdata(c.meta.r),
        .m_axis_result_tvalid(sub_valid)
    );

    floating_add_0 floating_add_m0 (
        .aclk(clk),
        .s_axis_a_tdata(c2.meta),
        .s_axis_a_tvalid(c2.valid),
        .s_axis_b_tdata(c3.meta),
        .s_axis_b_tvalid(c3.valid),
        .m_axis_result_tdata(c.meta.i),
        .m_axis_result_tvalid(add_valid)
    );

    assign c.valid = sub_valid & add_valid;
endmodule

// 11 + 17 cycles late from posedge to posedge
module complex_mul_adder (
    input wire clk,
    input wire cp_axis a1,
    input wire cp_axis b1,
    input wire cp_axis a2,
    input wire cp_axis b2,
    output wire cp_axis c
);
    cp_axis t1, t2;
    complex_multiplier cp_mul_1 (clk, a1, b1, t1);
    complex_multiplier cp_mul_2 (clk, a2, b2, t2);
    complex_adder cp_add_0 (clk, t1, t2, c);
endmodule

// 6 + 11 cycles late from posedge to posedge
module floating_mul_adder (
    input wire clk,
    input wire float_axis a1,
    input wire float_axis b1,
    input wire float_axis a2,
    input wire float_axis b2,
    output wire float_axis c
);

    float_axis t1, t2;
    floating_mul_0 fl_mul_1 (
        .aclk(clk), 
        .s_axis_a_tvalid(a1.valid),
        .s_axis_a_tdata(a1.meta.v),
        .s_axis_b_tvalid(b1.valid),
        .s_axis_b_tdata(b1.meta.v),
        .m_axis_result_tvalid(t1.valid),
        .m_axis_result_tdata(t1.meta.v)
    );

    floating_mul_0 fl_mul_2 (
        .aclk(clk),
        .s_axis_a_tvalid(a2.valid),
        .s_axis_a_tdata(a2.meta.v),
        .s_axis_b_tvalid(b2.valid),
        .s_axis_b_tdata(b2.meta.v),
        .m_axis_result_tvalid(t2.valid),
        .m_axis_result_tdata(t2.meta.v)
    );

    floating_add_0 fl_add_0 (
        .aclk(clk),
        .s_axis_a_tvalid(t1.valid),
        .s_axis_a_tdata(t1.meta.v),
        .s_axis_b_tvalid(t2.valid),
        .s_axis_b_tdata(t2.meta.v),
        .m_axis_result_tvalid(c.valid),
        .m_axis_result_tdata(c.meta.v)
    );
endmodule

// 6 cycles late from posedge to posedge
module complex_mul_float (
    input wire clk,
    input wire cp_axis a,
    input wire float_axis k,
    output wire cp_axis c
);

    logic v1, v2;
    floating_mul_0 fl_mul_1 (
        .aclk(clk), 
        .s_axis_a_tvalid(a.valid),
        .s_axis_a_tdata(a.meta.r),
        .s_axis_b_tvalid(k.valid),
        .s_axis_b_tdata(k.meta.v),
        .m_axis_result_tvalid(v1),
        .m_axis_result_tdata(c.meta.r)
    );

    floating_mul_0 fl_mul_2 (
        .aclk(clk),
        .s_axis_a_tvalid(a.valid),
        .s_axis_a_tdata(a.meta.i),
        .s_axis_b_tvalid(k.valid),
        .s_axis_b_tdata(k.meta.v),
        .m_axis_result_tvalid(v2),
        .m_axis_result_tdata(c.meta.i)
    );
    assign c.valid = v1 & v2;

endmodule

module complex_ax_plus_b #(
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire cp_axis a,
    input wire cp_axis x,
    input wire cp_axis b,
    output wire cp_axis c 
);
    cp_axis c0;
    complex_multiplier cp_mul (clk, a, x, c0);
    complex_adder cp_add (clk, c0, b, c);
endmodule


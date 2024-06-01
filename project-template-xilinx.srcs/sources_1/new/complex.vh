`ifndef _COMPLEX_HDR_VH_
`define _COMPLEX_HDR_VH_

localparam ONE_FL = 32'h3F800000;
localparam FIFTEEN_FL = 32'h41700000; // 15.0
localparam SIXTY_FL = 32'h42700000; // 60.0
localparam ONE_HUNDRED_FL = 32'h42C80000; // 100.0
localparam TWO_HUNDRED_FL = 32'h43480000; // 200.0
localparam NEG_0_5 = 32'hBF000000; // -0.5
localparam POS_1_5 = 32'h3FC00000; // 1.5
localparam ONE_CP = {ONE_FL, 32'b0};
localparam PI = 32'h40490FDB;

localparam FL_MUL_CYCS = 8;
localparam FL_ADD_CYCS = 11;
localparam FL_RECIPROCAL_SQRT_CYCS = 32;

localparam CP_MUL_CYCS = FL_MUL_CYCS + FL_ADD_CYCS;
localparam CP_ADD_CYCS = FL_ADD_CYCS;
localparam CP_MUL_ADD_CYCS = CP_MUL_CYCS + CP_ADD_CYCS;

localparam CALC_GIVENS_A2_B2_CYCS = FL_MUL_CYCS + FL_ADD_CYCS * 2;
localparam CALC_GIVENS_C3_CYCS = CALC_GIVENS_A2_B2_CYCS + FL_RECIPROCAL_SQRT_CYCS;
localparam CALC_GIVENS_COEF_C_S_CYCS = CALC_GIVENS_C3_CYCS + FL_MUL_CYCS;
localparam CALC_GIVENS_COEF_MUL_CYCS = CALC_GIVENS_COEF_C_S_CYCS + CP_MUL_CYCS;
localparam CALC_GIVENS_COEF_MUL_ADD_CYCS = CALC_GIVENS_COEF_MUL_CYCS + CP_ADD_CYCS + 1;
localparam CALC_GIVENS_SECOND_COEF_MUL_ADD_CYCS = CALC_GIVENS_COEF_MUL_ADD_CYCS + CP_MUL_ADD_CYCS + 1;
localparam CALC_GIVENS_ROTATIONS_CYCS = CALC_GIVENS_SECOND_COEF_MUL_ADD_CYCS;

localparam DATA_WIDTH = 32;
localparam SRAM_ADDR_WIDTH = 20;
localparam MAX_DEG = 6;

localparam SAMPLING_DIV_N = 32'd700;
localparam SAMPLING_STEP_COEF = 32'h3ABB3EE7; // 1/700

//localparam SAMPLING_DIV_N = 32'd2000;
//localparam SAMPLING_STEP_COEF = 32'h3A03126F; // 1/2000
//localparam SAMPLING_DIV_N = 32'd200;
//localparam SAMPLING_STEP_COEF = 32'h3BA3D70A; // 1/200

localparam POLY_X_HOLD_CYCS = CP_MUL_ADD_CYCS * (MAX_DEG - 1);

localparam QR_DECOMP_CYCS = CALC_GIVENS_ROTATIONS_CYCS * (MAX_DEG - 1);
localparam ITER_TIMES_EACH = 13;
localparam ITER_TIMES = ITER_TIMES_EACH * (MAX_DEG - 1);

localparam CP_DATA_WIDTH = 64;
localparam PIXEL_DATA_WIDTH = 4;
localparam PACKED_PIXEL_DATA_WIDTH = 64;
localparam PACKED_PIXEL_COUNT = PACKED_PIXEL_DATA_WIDTH / PIXEL_DATA_WIDTH;
localparam BRAM_1024_ADDR_WIDTH = 10;
localparam BRAM_GRAPH_MEM_DEPTH = (1 << 17);

localparam ROOTS_TO_PIXELS_CYCS = CP_MUL_CYCS + CP_ADD_CYCS;

localparam GM_MASTER_COUNT = 3;

localparam SHIFT_SUB = 2'b01;
localparam SHIFT_ADD = 2'b10;

localparam VGA_HSIZE = 1920;
localparam VGA_H_FRONT_PORCH = 88;
localparam VGA_H_SYNC_PULSE = 44;
localparam VGA_H_BACK_PORCH = 148;

// 2008 = 1920 + 88(Front Porch)
localparam VGA_HFP = VGA_HSIZE + VGA_H_FRONT_PORCH;

// 2052 = 1920 + 88 + 44(Sync pulse)
localparam VGA_HSP = VGA_HFP + VGA_H_SYNC_PULSE;

// 2200 = 1920 + 88 + 44 + 148(Back Porch)
localparam VGA_HMAX = VGA_HSP + VGA_H_BACK_PORCH;

localparam TOP_BAR_WIDTH = 144;
localparam VGA_VSIZE = 1080;
localparam VGA_V_FRONT_PORCH = 4;
localparam VGA_V_SYNC_PULSE = 5;
localparam VGA_V_BACK_PORCH = 36;

// 1084 = 1080 + 4(Front Porch)
localparam VGA_VFP = VGA_VSIZE + VGA_V_FRONT_PORCH;

// 1089 = 1080 + 4 + 5(Sync pulse)
localparam VGA_VSP = VGA_VFP + VGA_V_SYNC_PULSE;

// 1125 = 1080 + 4 + 5 + 36(Back Porch)
localparam VGA_VMAX = VGA_VSP + VGA_V_BACK_PORCH;

localparam VGA_RESOLUTION = VGA_HSIZE * VGA_VSIZE;
localparam GM_ADDR_MAX = VGA_RESOLUTION / PACKED_PIXEL_COUNT;
localparam SRAM_TOP_BAR_WIDTH = VGA_HSIZE * TOP_BAR_WIDTH * PIXEL_DATA_WIDTH / DATA_WIDTH;
localparam OPTION_COUNT = 7;

localparam BACKGROUND_RED = 8'd244;
localparam BACKGROUND_GREEN = 8'd240;
localparam BACKGROUND_BLUE = 8'd231;

typedef struct packed {
    logic [PIXEL_DATA_WIDTH - 1:0] v;
} pixel_data;

typedef struct packed {
    pixel_data [PACKED_PIXEL_DATA_WIDTH / PIXEL_DATA_WIDTH - 1:0] p;
} packed_pixel_data;


// floating point
typedef struct packed {
    logic [DATA_WIDTH - 1:0] v;
} float;

typedef struct packed {
    logic valid;
    float meta;
} float_axis;

// complex number
typedef struct packed {
    float r;
    float i;
} cp;

typedef struct packed {
    logic valid;
    cp meta;
} cp_axis;


// coefs of polynomial
typedef struct packed {
    cp [MAX_DEG:0] a;
} poly;

typedef struct packed {
    logic valid;
    poly meta;
} poly_axis;

typedef struct packed {
    logic mode;
    float range;
} sample_mode;

typedef struct packed {
    logic valid;
    sample_mode meta;
} sample_mode_axis;

typedef struct packed {
    logic valid;
    poly p_c;
    poly p_t1;
    poly p_t2;
    logic [2:0] ind_t1;
    logic [2:0] ind_t2;
    sample_mode spm;
} coef_axis;

// roots of polynomial
typedef struct packed {
    cp [MAX_DEG - 1:0] x;
} roots;

typedef struct packed {
    logic valid;
    roots meta;
} roots_axis;

// pixel parsed from roots
typedef struct packed {
    logic signed [DATA_WIDTH - 1:0] x;
    logic signed [DATA_WIDTH - 1:0] y;
} pixel;

typedef struct packed {
    logic valid;
    pixel meta;
} pixel_axis;

typedef struct packed {
    pixel [MAX_DEG - 1:0] p;
} pixels;

typedef struct packed {
    logic valid;
    pixels meta;
} pixels_axis;


// matrix
typedef struct packed {
    cp [MAX_DEG - 1:0] c;
} mat_row;

typedef struct packed {
    mat_row [MAX_DEG - 1:0] r;
} mat;

typedef struct packed {
    logic valid;
    mat meta;
} mat_axis;

// QR decomposition processing frame
typedef struct packed {
    mat r;
    logic [2:0] row_id;
    logic [2:0] col_id;
    logic [2:0] mul_mat_pos;
    logic [2:0] lim;
    logic dir;
    logic [1:0] shift;
    logic [$clog2(ITER_TIMES_EACH) - 1:0] iter;

    logic should_reset_mul_mat_pos;
    logic should_reset_row_id;
    logic should_start_new_iter;
    logic should_reduce_problem_scale;
    logic should_output;
    cp [MAX_DEG - 2:0] c;
    cp [MAX_DEG - 2:0] s;
    cp offset;
} qr;

typedef struct packed {
    logic valid;
    qr meta;
} qr_axis;



`define should_handle(b) (b.valid)
`define meta(b) (b.meta)
`define neg_fl(b) {b[31] ^ 1'b1, b[30:0]}
`define neg_cp(b) {`neg_fl(b.r), `neg_fl(b.i)}
`define conj(b) {b.r, `neg_fl(b.i)}


typedef enum logic [2:0] {
    ST_P2G_IDLE,
    ST_P2G_CHECK,
    ST_P2G_READ_PIXEL,
    ST_P2G_WAIT_READ_ACK,
    ST_P2G_WRITE_PIXEL,
    ST_P2G_WAIT_WRITE_ACK,

    ST_P2G_NEXT,
    ST_P2G_ERROR

} pixel2graph_status_t;

typedef enum logic [3:0] {
    ST_SYS_IDLE,
    ST_SYS_RESET_ALL,
    ST_SYS_DRAW_OPTION,
    ST_SYS_OPTION_SELECTION,
    ST_SYS_REFRESH_OPTION_SELECTION,
    ST_SYS_DRAW_BACKGROUND,
    ST_SYS_DRAW_TOP_BAR,
    ST_SYS_INPUT_CHOOSE_MODE,
    ST_SYS_MODE1_INPUT,
    ST_SYS_MODE1_RESET,
    ST_SYS_MODE1_RUNNING,
    ST_SYS_MODE1_FINISH
} system_status_t;

typedef enum logic [2:0] {
    ST_RST_IDLE,
    ST_RST_RUNNING,
    ST_RST_WRITE_ZERO,
    ST_RST_WAIT_WRITE_ACK,
    ST_RST_FIN
} reset_all_status_t;

typedef enum logic [3:0] {
    ST_DTB_IDLE,
    ST_DTB_RUNNING,
    ST_DTB_WAIT_READ_ACK1,
    ST_DTB_READ2,
    ST_DTB_WAIT_READ_ACK2,
    ST_DTB_WAIT_WRITE_ACK,
    ST_DTB_REFRESH_OPTION_BAR,
    ST_DTB_READ_OPTION_BAR,
    ST_DTB_WRITE_OPTION_BAR,
    ST_DTB_WAIT_WRITE_OPTION_BAR,
    ST_DTB_FIN
} draw_top_bar_status_t;


typedef enum logic [2:0] {
    ST_SAMP_IDLE,
    ST_SAMP_CALC_STEP,
    ST_SAMP_SAMPLING,
    ST_SAMP_FIN
} sampling_status_t;

typedef enum logic [2:0] {
    ST_GENP_IDLE,
    ST_GENP_READ_T1_T2,
    ST_GENP_CALC_STEP,
    ST_GENP_DIV,
    ST_GENP_FIN
} gen_poly_status_t;

typedef enum logic [1:0] {
    ST_QR_INIT,
    ST_QR_FROM_INPUT,
    ST_QR_FROM_MUL_MAT
} qr_decomp_status_t;

// master signal input
typedef struct packed {
    logic ack;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] dat;
} wbm_signal_recv;

// master signal output
typedef struct packed {
    logic cyc;
    logic stb;
    logic [$clog2(BRAM_GRAPH_MEM_DEPTH) - 1:0] adr;
    packed_pixel_data dat;
    logic we;
} wbm_signal_send;

typedef struct packed {
    logic ack;
    logic [DATA_WIDTH - 1:0] dat;
} sram_signal_recv;

typedef struct packed {
    logic cyc;
    logic stb;
    logic [SRAM_ADDR_WIDTH - 1:0] adr;
    logic [DATA_WIDTH - 1:0] dat;
    logic we;
} sram_signal_send;

`endif



`ifndef _COMPLEX_HDR_VH_
`define _COMPLEX_HDR_VH_

localparam ONE_FL = 32'h3F800000;
localparam ONE_HUNDRED_FL = 32'h42C80000;
localparam NEG_0_5 = 32'hBF000000; // -0.5
localparam ONE_CP = {ONE_FL, 32'b0};
localparam PI = 32'h40490FDB;

localparam FL_MUL_CYCS = 6;
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
localparam MAX_DEG = 6;
localparam SAMPLING_DIV_N = 32'd2000;
localparam SAMPLING_STEP_COEF = 32'h3A03126F; // 1/2000

localparam POLY_X_HOLD_CYCS = CP_MUL_ADD_CYCS * (MAX_DEG - 1);

localparam QR_DECOMP_CYCS = CALC_GIVENS_ROTATIONS_CYCS * (MAX_DEG - 1);
localparam ITER_TIMES = 100;

localparam CP_DATA_WIDTH = 64;
localparam PIXEL_DATA_WIDTH = 4;
localparam PACKED_PIXEL_DATA_WIDTH = 16;
localparam BRAM_1024_ADDR_WIDTH = 10;
localparam BRAM_524288_ADDR_WIDTH = 19;

localparam ROOTS_TO_PIXELS_CYCS = CP_MUL_CYCS + CP_ADD_CYCS;

localparam GM_MASTER_COUNT = 2;


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
    poly [MAX_DEG:0] p;
} coef;

typedef struct packed {
    logic valid;
    coef t1;
    coef t2;
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
    logic [DATA_WIDTH - 1:0] x;
    logic [DATA_WIDTH - 1:0] y;
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
    mat a;
    mat r;
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
    ST_ITER_INIT,
    ST_ITER_IN_BATCH,
    ST_ITER_FIN,
    ST_ITER_ERROR
} iteration_status_t;

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
    ST_SYS_INPUT_CHOOSE_MODE,
    ST_SYS_MODE1_INPUT,
    ST_SYS_MODE1_RESET,
    ST_SYS_MODE1_RUNNING,
    ST_SYS_MODE1_FINISH
} system_status_t;

typedef enum logic [2:0] {
    ST_SAMP_IDLE,
    ST_SAMP_CALC_STEP,
    ST_SAMP_SAMPLING,
    ST_SAMP_FIN
} sampling_status_t;

// master signal input
typedef struct packed {
    logic ack;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] dat;
} wbm_signal_recv;

// master signal output
typedef struct packed {
    logic cyc;
    logic stb;
    logic [BRAM_524288_ADDR_WIDTH - 1:0] adr;
    logic [PACKED_PIXEL_DATA_WIDTH - 1:0] dat;
    logic we;
} wbm_signal_send;


`endif



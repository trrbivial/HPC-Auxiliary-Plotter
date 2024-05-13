`ifndef _COMPLEX_HDR_VH_
`define _COMPLEX_HDR_VH_

localparam ONE_FL = 32'h3F800000;
localparam ONE_CP = {ONE_FL, 32'b0};

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

localparam QR_DECOMP_CYCS = CALC_GIVENS_ROTATIONS_CYCS * (MAX_DEG - 1);
localparam ITER_TIMES = 2;

localparam CP_DATA_WIDTH = 64;
localparam BRAM_1024_ADDR_WIDTH = 10;

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
    cp [MAX_DEG - 1:0] a;
} poly;

typedef struct packed {
    logic valid;
    poly meta;
} poly_axis;

// roots of polynomial
typedef struct packed {
    cp [MAX_DEG - 1:0] x;
} roots;

typedef struct packed {
    logic valid;
    roots meta;
} roots_axis;


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
    INIT,
    IN_BATCH,
    FIN,
    ERROR
} iteration_status_t;
`endif


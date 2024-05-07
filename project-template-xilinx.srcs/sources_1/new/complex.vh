`ifndef _COMPLEX_HDR_VH_
`define _COMPLEX_HDR_VH_

localparam ONE_FL = 32'h3F800000;
localparam ONE_CP = {ONE_FL, 32'b0};

localparam FL_MUL_CYCS = 6;
localparam FL_ADD_CYCS = 11;
localparam FL_RECIPROCAL_SQRT_CYCS = 32;

localparam CP_MUL_CYCS = FL_MUL_CYCS + FL_ADD_CYCS;
localparam CP_ADD_CYCS = FL_ADD_CYCS;

localparam START_CALC_GIVENS_COEF_C_CYCS = FL_MUL_CYCS + FL_ADD_CYCS * 2 + FL_RECIPROCAL_SQRT_CYCS;
localparam CALC_GIVENS_COEF_CYCS = FL_MUL_CYCS + FL_ADD_CYCS * 2 + FL_RECIPROCAL_SQRT_CYCS + FL_MUL_CYCS;

localparam DATA_WIDTH = 32;
localparam MAX_DEG = 6;

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
    cp a [MAX_DEG - 1:0];
} poly;

typedef struct packed {
    logic valid;
    poly meta;
} poly_axis;

// roots of polynomial
typedef struct packed {
    cp x [MAX_DEG - 1:0];
} roots;

typedef struct packed {
    logic valid;
    roots meta;
} roots_axis;


// matrix
typedef struct packed {
    cp c [MAX_DEG - 1:0];
} mat_row;

typedef struct packed {
    mat_row r [MAX_DEG - 1:0];
} mat;

typedef struct packed {
    logic valid;
    mat meta;
} mat_axis;

// QR decomposition processing frame
typedef struct packed {
    mat q;
    mat r;
} qr;

typedef struct packed {
    logic valid;
    qr meta;
} qr_axis;


`define should_handle(b) (b.valid)
`define meta(b) (b.meta)
`define neg_fl(b) ({b[31] ^ 1, b[30:0]})
`define neg_cp(b) ({`neg_fl(b.r), `neg_fl(b.i)})
`define conj(b) ({b.r, `neg_fl(b.i)})


typedef enum logic [2:0] {
    INIT,
    STEP1_QR_DECOMP,
    STEP2_CALC_NEW_MAT,
    FIN,
    ERROR
} roots_serial_status_t;
`endif


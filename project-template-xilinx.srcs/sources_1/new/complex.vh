`ifndef _COMPLEX_HDR_VH_
`define _COMPLEX_HDR_VH_

typedef struct packed {
    logic [31:0] v;
} float;

typedef struct packed {
    logic valid;
    float meta;
} float_axis;

typedef struct packed {
    float r;
    float i;
} cp;

typedef struct packed {
    logic valid;
    cp meta;
} cp_axis;


`define should_handle(b) (b.valid)
`define meta(b) (b.meta)
`endif


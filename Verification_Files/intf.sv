interface intf #(parameter int DATA_WIDTH = 32, parameter int ADDR_WIDTH = 16);

    logic ACLK;
    logic ARESETn;

    // =========================================================
    // Write Address Channel
    // =========================================================
    logic [ADDR_WIDTH-1:0] expected_AWADDR, actual_AWADDR;
    logic [7:0]            expected_AWLEN,  actual_AWLEN;
    logic [2:0]            expected_AWSIZE, actual_AWSIZE;
    logic                  expected_AWVALID, actual_AWVALID;
    logic                  expected_AWREADY, actual_AWREADY;

    // =========================================================
    // Write Data Channel
    // =========================================================
    logic [DATA_WIDTH-1:0] expected_WDATA[], actual_WDATA[];
    logic                  expected_WLAST, actual_WLAST;
    logic                  expected_WVALID, actual_WVALID;
    logic                  expected_WREADY, actual_WREADY;

    // =========================================================
    // Write Response Channel
    // =========================================================
    logic [1:0]            expected_BRESP, actual_BRESP;
    logic                  expected_BVALID, actual_BVALID;
    logic                  expected_BREADY, actual_BREADY;

    // =========================================================
    // Read Address Channel
    // =========================================================
    logic [ADDR_WIDTH-1:0] expected_ARADDR, actual_ARADDR;
    logic [7:0]            expected_ARLEN,  actual_ARLEN;
    logic [2:0]            expected_ARSIZE, actual_ARSIZE;
    logic                  expected_ARVALID, actual_ARVALID;
    logic                  expected_ARREADY, actual_ARREADY;

    // =========================================================
    // Read Data Channel
    // =========================================================
    logic [DATA_WIDTH-1:0] expected_RDATA[], actual_RDATA[];
    logic [1:0]            expected_RRESP, actual_RRESP;
    logic                  expected_RLAST, actual_RLAST;
    logic                  expected_RVALID, actual_RVALID;
    logic                  expected_RREADY, actual_RREADY;

endinterface

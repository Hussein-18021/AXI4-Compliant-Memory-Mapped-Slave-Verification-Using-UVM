interface intf #(parameter int DATA_WIDTH = 32, parameter int ADDR_WIDTH = 16);

    logic ACLK;
    logic ARESETn;

    // =========================================================
    // Write Address Channel - DUT Signals
    // =========================================================
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic [2:0]            AWSIZE;
    logic                  AWVALID;
    logic                  AWREADY;

    // =========================================================
    // Write Data Channel - DUT Signals
    // =========================================================
    logic [DATA_WIDTH-1:0] WDATA;
    logic                  WLAST;
    logic                  WVALID;
    logic                  WREADY;

    // =========================================================
    // Write Response Channel - DUT Signals
    // =========================================================
    logic [1:0]            BRESP;
    logic                  BVALID;
    logic                  BREADY;

    // =========================================================
    // Read Address Channel - DUT Signals
    // =========================================================
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic [2:0]            ARSIZE;
    logic                  ARVALID;
    logic                  ARREADY;

    // =========================================================
    // Read Data Channel - DUT Signals
    // =========================================================
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RLAST;
    logic                  RVALID;
    logic                  RREADY;

    // =========================================================
    // EXPECTED SIGNALS FOR GOLDEN MODEL
    // =========================================================
    
    // Write Address Channel - Expected
    logic [ADDR_WIDTH-1:0] expected_AWADDR;
    logic [7:0]            expected_AWLEN;
    logic [2:0]            expected_AWSIZE;
    logic                  expected_AWVALID;
    logic                  expected_AWREADY;

    // Write Data Channel - Expected
    logic [DATA_WIDTH-1:0] expected_WDATA[];
    logic                  expected_WLAST;
    logic                  expected_WVALID;
    logic                  expected_WREADY;

    // Write Response Channel - Expected
    logic [1:0]            expected_BRESP;
    logic                  expected_BVALID;
    logic                  expected_BREADY;

    // Read Address Channel - Expected
    logic [ADDR_WIDTH-1:0] expected_ARADDR;
    logic [7:0]            expected_ARLEN;
    logic [2:0]            expected_ARSIZE;
    logic                  expected_ARVALID;
    logic                  expected_ARREADY;

    // Read Data Channel - Expected
    logic [DATA_WIDTH-1:0] expected_RDATA[];
    logic [1:0]            expected_RRESP;
    logic                  expected_RLAST;
    logic                  expected_RVALID;
    logic                  expected_RREADY;

endinterface
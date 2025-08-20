`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction #(parameter int DATA_WIDTH = 32, parameter int ADDR_WIDTH = 16) extends uvm_sequence_item;
    typedef enum {READ, WRITE} op_t;
    rand op_t OP;
    // =========================================================
    // Write Address Channel
    // =========================================================
    rand logic [ADDR_WIDTH-1:0] expected_AWADDR, actual_AWADDR;
    rand logic [7:0]            expected_AWLEN,  actual_AWLEN;
    rand logic [2:0]            expected_AWSIZE, actual_AWSIZE;
    rand logic                  expected_AWVALID, actual_AWVALID;
    rand logic                  expected_AWREADY, actual_AWREADY;

    // =========================================================
    // Write Data Channel
    // =========================================================
    rand logic [DATA_WIDTH-1:0] expected_WDATA[], actual_WDATA[];
    rand logic                  expected_WLAST, actual_WLAST;
    rand logic                  expected_WVALID, actual_WVALID;
    rand logic                  expected_WREADY, actual_WREADY;

    // =========================================================
    // Write Response Channel
    // =========================================================
    rand logic [1:0]            expected_BRESP, actual_BRESP;
    rand logic                  expected_BVALID, actual_BVALID;
    rand logic                  expected_BREADY, actual_BREADY;

    // =========================================================
    // Read Address Channel
    // =========================================================
    rand logic [ADDR_WIDTH-1:0] expected_ARADDR, actual_ARADDR;
    rand logic [7:0]            expected_ARLEN,  actual_ARLEN;
    rand logic [2:0]            expected_ARSIZE, actual_ARSIZE;
    rand logic                  expected_ARVALID, actual_ARVALID;
    rand logic                  expected_ARREADY, actual_ARREADY;

    // =========================================================
    // Read Data Channel
    // =========================================================
    rand logic [DATA_WIDTH-1:0] expected_RDATA[], actual_RDATA[];
    rand logic [1:0]            expected_RRESP, actual_RRESP;
    rand logic                  expected_RLAST, actual_RLAST;
    rand logic                  expected_RVALID, actual_RVALID;
    rand logic                  expected_RREADY, actual_RREADY;


    // Factory registration
    `uvm_object_utils_begin(transaction)
        `uvm_field_enum(op_t, OP, UVM_DEFAULT)

        // Write Address
        `uvm_field_int(expected_AWADDR, UVM_DEFAULT)
        `uvm_field_int(actual_AWADDR,   UVM_DEFAULT)
        `uvm_field_int(expected_AWLEN,  UVM_DEFAULT)
        `uvm_field_int(actual_AWLEN,    UVM_DEFAULT)
        `uvm_field_int(expected_AWSIZE, UVM_DEFAULT)
        `uvm_field_int(actual_AWSIZE,   UVM_DEFAULT)
        `uvm_field_int(expected_AWVALID,UVM_DEFAULT)
        `uvm_field_int(actual_AWVALID,  UVM_DEFAULT)
        `uvm_field_int(expected_AWREADY,UVM_DEFAULT)
        `uvm_field_int(actual_AWREADY,  UVM_DEFAULT)

        // Write Data
        `uvm_field_array_int(expected_WDATA,  UVM_DEFAULT)
        `uvm_field_array_int(actual_WDATA,    UVM_DEFAULT)
        `uvm_field_int(expected_WLAST,  UVM_DEFAULT)
        `uvm_field_int(actual_WLAST,    UVM_DEFAULT)
        `uvm_field_int(expected_WVALID, UVM_DEFAULT)
        `uvm_field_int(actual_WVALID,   UVM_DEFAULT)
        `uvm_field_int(expected_WREADY, UVM_DEFAULT)
        `uvm_field_int(actual_WREADY,   UVM_DEFAULT)

        // Write Response
        `uvm_field_int(expected_BRESP,  UVM_DEFAULT)
        `uvm_field_int(actual_BRESP,    UVM_DEFAULT)
        `uvm_field_int(expected_BVALID, UVM_DEFAULT)
        `uvm_field_int(actual_BVALID,   UVM_DEFAULT)
        `uvm_field_int(expected_BREADY, UVM_DEFAULT)
        `uvm_field_int(actual_BREADY,   UVM_DEFAULT)

        // Read Address
        `uvm_field_int(expected_ARADDR, UVM_DEFAULT)
        `uvm_field_int(actual_ARADDR,   UVM_DEFAULT)
        `uvm_field_int(expected_ARLEN,  UVM_DEFAULT)
        `uvm_field_int(actual_ARLEN,    UVM_DEFAULT)
        `uvm_field_int(expected_ARSIZE, UVM_DEFAULT)
        `uvm_field_int(actual_ARSIZE,   UVM_DEFAULT)
        `uvm_field_int(expected_ARVALID,UVM_DEFAULT)
        `uvm_field_int(actual_ARVALID,  UVM_DEFAULT)
        `uvm_field_int(expected_ARREADY,UVM_DEFAULT)
        `uvm_field_int(actual_ARREADY,  UVM_DEFAULT)

        // Read Data
        `uvm_field_array_int(expected_RDATA,  UVM_DEFAULT)
        `uvm_field_array_int(actual_RDATA,    UVM_DEFAULT)
        `uvm_field_int(expected_RRESP,  UVM_DEFAULT)
        `uvm_field_int(actual_RRESP,    UVM_DEFAULT)
        `uvm_field_int(expected_RLAST,  UVM_DEFAULT)
        `uvm_field_int(actual_RLAST,    UVM_DEFAULT)
        `uvm_field_int(expected_RVALID, UVM_DEFAULT)
        `uvm_field_int(actual_RVALID,   UVM_DEFAULT)
        `uvm_field_int(expected_RREADY, UVM_DEFAULT)
        `uvm_field_int(actual_RREADY,   UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "transaction");
        super.new(name);
    endfunction

    constraint burst_size_c {
        actual_WDATA.size() == actual_AWLEN + 1;  
        actual_RDATA.size() == actual_ARLEN + 1;  
        actual_AWLEN inside {[0:15]};             
        actual_ARLEN inside {[0:15]};
        actual_AWSIZE == 'd4;
        actual_ARSIZE == 'd4;
    }

endclass
`endif

`include "intf.sv"
`include "uvm_macros.svh"
import package_::*;
import uvm_pkg::*;
module top;
    
    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 16;

    intf #(DATA_WIDTH, ADDR_WIDTH) vif();

    axi4 #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
        .ACLK    (vif.ACLK),
        .ARESETn (vif.ARESETn),
        .AWADDR  (vif.actual_AWADDR),
        .AWLEN   (vif.actual_AWLEN),
        .AWSIZE  (vif.actual_AWSIZE),
        .AWVALID (vif.actual_AWVALID),
        .AWREADY (vif.actual_AWREADY),
        .WDATA   (vif.actual_WDATA),
        .WLAST   (vif.actual_WLAST),
        .WVALID  (vif.actual_WVALID),
        .WREADY  (vif.actual_WREADY),
        .BRESP   (vif.actual_BRESP),
        .BVALID  (vif.actual_BVALID),
        .BREADY  (vif.actual_BREADY),
        .ARADDR  (vif.actual_ARADDR),
        .ARLEN   (vif.actual_ARLEN),
        .ARSIZE  (vif.actual_ARSIZE),
        .ARVALID (vif.actual_ARVALID),
        .ARREADY (vif.actual_ARREADY),
        .RDATA   (vif.actual_RDATA),
        .RRESP   (vif.actual_RRESP),
        .RLAST   (vif.actual_RLAST),
        .RVALID  (vif.actual_RVALID),
        .RREADY  (vif.actual_RREADY)
    );

    initial begin
        vif.ARESETn = 0;
        #2ns 
        vif.ARESETn = 1;
    end
    
    initial begin 
        vif.ACLK=0;
        forever begin
            #2ns vif.ACLK = ~ vif.ACLK;
        end
    end

    initial begin
        uvm_config_db #(uvm_active_passive_enum)::set(null, "uvm_test_top.env.agent_", "is_active", UVM_ACTIVE);
        uvm_config_db #(virtual intf)::set(null, "uvm_test_top.env.agent_.*", "intf", vif);
        run_test("test");
    end

endmodule
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
        .AWADDR  (vif.AWADDR),
        .AWLEN   (vif.AWLEN),
        .AWSIZE  (vif.AWSIZE),
        .AWVALID (vif.AWVALID),
        .AWREADY (vif.AWREADY),
        .WDATA   (vif.WDATA),
        .WLAST   (vif.WLAST),
        .WVALID  (vif.WVALID),
        .WREADY  (vif.WREADY),
        .BRESP   (vif.BRESP),
        .BVALID  (vif.BVALID),
        .BREADY  (vif.BREADY),
        .ARADDR  (vif.ARADDR),
        .ARLEN   (vif.ARLEN),
        .ARSIZE  (vif.ARSIZE),
        .ARVALID (vif.ARVALID),
        .ARREADY (vif.ARREADY),
        .RDATA   (vif.RDATA),
        .RRESP   (vif.RRESP),
        .RLAST   (vif.RLAST),
        .RVALID  (vif.RVALID),
        .RREADY  (vif.RREADY)
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
        uvm_config_db #(virtual intf)::set(null, "uvm_test_top.env.scoreboard_", "intf", vif);

        run_test("test");
    end

endmodule
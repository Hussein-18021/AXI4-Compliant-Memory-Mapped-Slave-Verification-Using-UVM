`ifndef DRIVER_SVH
`define DRIVER_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
`include "common_cfg.sv"
import uvm_pkg::*;
class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)
    virtual intf vif;
    common_cfg m_cfg;
    function new(string name= "driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif)) 
            `uvm_fatal(get_full_name(), {"virtual interface must be set for:", ".intf"});
        
        if(!uvm_config_db#(common_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal("DRV_CFG", "Failed to get m_cfg from config DB");

        `uvm_info(get_type_name(), "Driver build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction

    task reset_signals();
        vif.actual_AWVALID <= 0;
        vif.actual_WVALID  <= 0;
        vif.actual_WLAST   <= 0;
        vif.actual_BREADY  <= 0;
        vif.actual_ARVALID <= 0;
        vif.actual_RREADY  <= 0;
    endtask

    task run_phase(uvm_phase phase);
        transaction req;
        reset_signals();
        forever begin
            seq_item_port.get_next_item(req);
            case(req.OP)
                transaction#(32,16)::WRITE: drive_write(req);
                transaction#(32,16)::READ : drive_read(req);
                default: `uvm_error(get_type_name(), "Unknown OP type")
            endcase
            -> m_cfg.stimulus_sent_e;
            seq_item_port.item_done();
        end
    endtask

    // -------------------
    // WRITE driver
    // -------------------
    task drive_write(transaction req);
        @(posedge vif.ACLK iff vif.ARESETn);

        `uvm_info("DRV", $sformatf("WRITE: AWADDR=0x%0h, AWLEN=%0d, WDATA.size=%0d", req.actual_AWADDR, req.actual_AWLEN, req.actual_WDATA.size()), UVM_MEDIUM)

        // Drive address channel
        vif.actual_AWADDR  <= req.actual_AWADDR;
        vif.actual_AWLEN   <= req.actual_AWLEN;
        vif.actual_AWSIZE  <= req.actual_AWSIZE;
        vif.actual_AWVALID <= req.actual_AWVALID;

        wait(vif.actual_AWREADY);
        @(posedge vif.ACLK);
        vif.actual_AWVALID <= 0;

        // Drive data beats - use dynamic array
        for (int i = 0; i <= req.actual_AWLEN; i++) begin
            vif.actual_WDATA  <= req.actual_WDATA[i];
            vif.actual_WLAST  <= (i == req.actual_AWLEN);
            vif.actual_WVALID <= req.actual_WVALID;

            `uvm_info("DRV", $sformatf("WRITE Beat %0d: WDATA=0x%0h, WLAST=%0b", i, req.actual_WDATA[i], (i == req.actual_AWLEN)), UVM_HIGH)

            wait(vif.actual_WREADY);
            @(posedge vif.ACLK);
        end
        vif.actual_WVALID <= 0;
        vif.actual_WLAST  <= 0;

        // Response
        vif.actual_BREADY <= req.actual_BREADY;
        wait(vif.actual_BVALID);
        @(posedge vif.ACLK);
        vif.actual_BREADY <= 0;
    endtask

    // -------------------
    // read driver
    // -------------------
    task drive_read(transaction req);
        @(posedge vif.ACLK iff vif.ARESETn);

        `uvm_info("DRV", $sformatf("READ: ARADDR=0x%0h, ARLEN=%0d", req.actual_ARADDR, req.actual_ARLEN), UVM_MEDIUM)

        // Initialize RDATA array to proper size
        req.actual_RDATA = new[req.actual_ARLEN + 1];

        // Drive address channel
        vif.actual_ARADDR  <= req.actual_ARADDR;
        vif.actual_ARLEN   <= req.actual_ARLEN;
        vif.actual_ARSIZE  <= req.actual_ARSIZE;
        vif.actual_ARVALID <= req.actual_ARVALID;

        wait(vif.actual_ARREADY);
        @(posedge vif.ACLK);
        vif.actual_ARVALID <= 0;

        // Read data - capture each beat into dynamic array
        vif.actual_RREADY <= req.actual_RREADY;
        for (int i = 0; i <= req.actual_ARLEN; i++) begin
            wait(vif.actual_RVALID);
            req.actual_RDATA[i] = vif.actual_RDATA;
            req.actual_RRESP = vif.actual_RRESP;
            
            `uvm_info("DRV", $sformatf("READ Beat %0d: RDATA=0x%0h, RRESP=%0b, RLAST=%0b", i, vif.actual_RDATA, vif.actual_RRESP, vif.actual_RLAST), UVM_HIGH)
            
            if (vif.actual_RLAST) break;
            @(posedge vif.ACLK);
        end
        vif.actual_RREADY <= 0;
        
        `uvm_info("DRV", $sformatf("READ Complete: Captured %0d beats", req.actual_RDATA.size()), UVM_MEDIUM)
    endtask


endclass
`endif
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
        vif.AWVALID = 0;
        vif.WVALID  = 0;
        vif.WLAST   = 0;
        vif.BREADY  = 0;
        vif.ARVALID = 0;
        vif.RREADY  = 0;
        vif.WDATA   = 0;        // Single signal, not array
        vif.AWADDR  = 0;
        vif.AWLEN   = 0;
        vif.AWSIZE  = 0;
        vif.ARADDR  = 0;
        vif.ARLEN   = 0;
        vif.ARSIZE  = 0;
    endtask

    task run_phase(uvm_phase phase);
        transaction req;
        reset_signals();
        forever begin
            seq_item_port.get_next_item(req);
            case(req.OP)
                transaction#()::WRITE: drive_write(req);
                transaction#()::read : drive_read(req);
                default: `uvm_error(get_type_name(), "Unknown OP type")
            endcase
            -> m_cfg.stimulus_sent_e;
            seq_item_port.item_done();
        end
    endtask

    task drive_write(transaction req);
        int burst_length;
        @(posedge vif.ACLK iff vif.ARESETn);

        burst_length = req.AWLEN + 1; // AWLEN is 0-based, so actual length is AWLEN+1
        
        if (req.WDATA.size() != burst_length) begin
            `uvm_error("DRV", $sformatf("WDATA size (%0d) doesn't match burst length (%0d)", 
                      req.WDATA.size(), burst_length))
            return;
        end
        `uvm_info("DRV", $sformatf("WRITE BURST: AWADDR=0x%0h, AWLEN=%0d (burst_length=%0d), WDATA.size=%0d", 
                req.AWADDR, req.AWLEN, burst_length, req.WDATA.size()), UVM_MEDIUM)

        fork
            drive_aw_channel(req);
            drive_w_channel(req, burst_length);
        join
        
        drive_b_channel(req);
    endtask

    task drive_aw_channel(transaction req);
        `uvm_info("DRV", "Starting AW channel", UVM_HIGH)
        
        vif.AWADDR  <= req.AWADDR;
        vif.AWLEN   <= req.AWLEN;
        vif.AWSIZE  <= req.AWSIZE;
        vif.AWVALID <= 1'b1;

        fork
            wait(vif.AWREADY);
            begin
                repeat(1000) @(posedge vif.ACLK);
                `uvm_error("DRV", "AWREADY timeout")
            end
        join_any
        disable fork;
        
        `uvm_info("DRV", "AW channel handshake completed", UVM_HIGH)
        
        @(posedge vif.ACLK);
        vif.AWVALID <= 1'b0;
    endtask

    task drive_w_channel(transaction req, int burst_length);
        `uvm_info("DRV", $sformatf("Starting W channel - %0d beats", burst_length), UVM_HIGH)
        
        for (int i = 0; i < burst_length; i++) begin
            
            vif.WDATA <= req.WDATA[i];  // Drive single WDATA signal
            vif.WLAST <= (i == (burst_length - 1)) ? 1'b1 : 1'b0;
            vif.WVALID <= 1'b1;

            `uvm_info("DRV", $sformatf("Write Beat %0d/%0d: WDATA=0x%0h, WLAST=%0b", 
                     i+1, burst_length, req.WDATA[i], (i == (burst_length - 1))), UVM_HIGH)

            fork
                wait(vif.WREADY);
                begin
                    repeat(1000) @(posedge vif.ACLK);
                    `uvm_error("DRV", $sformatf("WREADY timeout on beat %0d", i))
                end
            join_any
            disable fork;
            
            `uvm_info("DRV", $sformatf("Beat %0d handshake completed", i), UVM_HIGH)
            
            @(posedge vif.ACLK);
        end
        
        vif.WVALID <= 1'b0;
        vif.WLAST  <= 1'b0;
        
        `uvm_info("DRV", "W channel burst completed", UVM_HIGH)
    endtask

    task drive_b_channel(transaction req);
        `uvm_info("DRV", "Waiting for B channel response", UVM_HIGH)
        
        vif.BREADY <= req.BREADY;
           
        req.BRESP = vif.BRESP;
        `uvm_info("DRV", $sformatf("Write Response: BRESP=0x%0h", req.BRESP), UVM_MEDIUM)
        
        @(posedge vif.ACLK);
        vif.BREADY <= 1'b0;
        
        `uvm_info("DRV", "B channel response completed", UVM_HIGH)
    endtask

    task drive_read(transaction req);
        int burst_length;
        @(posedge vif.ACLK iff vif.ARESETn);

        burst_length = req.ARLEN + 1;
        
        `uvm_info("DRV", $sformatf("READ BURST: ARADDR=0x%0h, ARLEN=%0d (burst_length=%0d)", 
                 req.ARADDR, req.ARLEN, burst_length), UVM_MEDIUM)

        req.RDATA = new[burst_length];

        drive_ar_channel(req);
        drive_r_channel(req, burst_length);
    endtask

    task drive_ar_channel(transaction req);
        `uvm_info("DRV", "Starting AR channel", UVM_HIGH)
        
        vif.ARADDR  <= req.ARADDR;
        vif.ARLEN   <= req.ARLEN;
        vif.ARSIZE  <= req.ARSIZE;
        vif.ARVALID <= 1'b1;
        
        `uvm_info("DRV", "AR channel handshake completed", UVM_HIGH)

        @(posedge vif.ACLK);
        vif.ARVALID <= 1'b0;
    endtask

    task drive_r_channel(transaction req, int burst_length);
        `uvm_info("DRV", $sformatf("Starting R channel - expecting %0d beats", burst_length), UVM_HIGH)
        
        vif.RREADY <= req.RREADY;
        
        for (int i = 0; i < burst_length; i++) begin
            
            fork
                wait(vif.RVALID);
                begin
                    repeat(1000) @(posedge vif.ACLK);
                    `uvm_error("DRV", $sformatf("RVALID timeout on beat %0d", i))
                end
            join_any
            disable fork;
            
            req.RDATA[i] = vif.RDATA;  // Capture single RDATA signal
            req.RRESP = vif.RRESP;
            
            `uvm_info("DRV", $sformatf("Read Beat %0d/%0d: RDATA=0x%0h, RRESP=0x%0h, RLAST=%0b", 
                     i+1, burst_length, req.RDATA[i], vif.RRESP, vif.RLAST), UVM_HIGH)
            
            if (vif.RLAST) 
                begin
                    if (i != (burst_length - 1)) 
                        begin
                            `uvm_warning("DRV", $sformatf("RLAST asserted early at beat %0d, expected at beat %0d", 
                                        i, burst_length - 1))
                        end
                    break;
                end 
            else if (i == (burst_length - 1)) 
                begin
                    `uvm_error("DRV", "RLAST not asserted on final beat")
                end
            
            @(posedge vif.ACLK);
        end
        
        vif.RREADY <= 1'b0;
        
        `uvm_info("DRV", $sformatf("R channel burst completed: %0d beats received", burst_length), UVM_MEDIUM)
    endtask

endclass
`endif
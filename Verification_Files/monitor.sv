`ifndef MONITOR_SVH
`define MONITOR_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
`include "common_cfg.sv"
import uvm_pkg::*;

class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)
    common_cfg m_cfg;
    virtual intf vif;
    uvm_analysis_port #(transaction) ap;
    
    function new(string name= "monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new ("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Monitor build phase - UVM_MEDIUM", UVM_MEDIUM)

        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif)) 
            `uvm_fatal(get_full_name(), "Failed to get interface");

        if(!uvm_config_db#(common_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal(get_full_name(), "Failed to get m_cfg from config DB");    
    endfunction

    task run_phase (uvm_phase phase);
        transaction tr;
        forever begin
            @(posedge vif.ACLK);
            
            // Detect write transaction start
            if (vif.AWVALID && vif.AWREADY && vif.ARESETn) begin
                tr = transaction#()::type_id::create("write_tr");
                tr.OP = transaction#()::WRITE;
                tr.AWADDR = vif.AWADDR;
                tr.AWLEN = vif.AWLEN;
                tr.AWSIZE = vif.AWSIZE;
                
                `uvm_info("MON", $sformatf("Write transaction detected: ADDR=0x%0h, LEN=%0d", 
                         tr.AWADDR, tr.AWLEN), UVM_MEDIUM)
                
                // FIXED: Proper AWLEN validation - check for reasonable burst lengths
                if (tr.AWLEN <= 8'd255) begin  // AXI4 allows 0-255, but practical limit
                    tr.WDATA = new[tr.AWLEN + 1];
                    
                    // Capture write data beat by beat
                    for (int i = 0; i <= tr.AWLEN; i++) begin
                        // Wait for valid data beat
                        do begin
                            @(posedge vif.ACLK);
                        end while (!(vif.WVALID && vif.WREADY) || !vif.ARESETn);
                        
                        if (!vif.ARESETn) break; // Exit if reset
                        
                        tr.WDATA[i] = vif.WDATA;
                        `uvm_info("MON", $sformatf("Captured WDATA[%0d] = 0x%0h", i, vif.WDATA), UVM_HIGH)
                        
                        // Check WLAST signal
                        if (i == tr.AWLEN && !vif.WLAST) begin
                            `uvm_error("MON", "WLAST not asserted on final write beat");
                        end
                    end
                    
                    // Capture write response if reset is not active
                    if (vif.ARESETn) begin
                        do begin
                            @(posedge vif.ACLK);
                        end while (!(vif.BVALID && vif.BREADY) || !vif.ARESETn);
                        
                        if (vif.ARESETn) begin
                            tr.BRESP = vif.BRESP;
                            `uvm_info("MON", $sformatf("Write transaction completed: ADDR=0x%0h, LEN=%0d, BRESP=0x%0h", 
                                     tr.AWADDR, tr.AWLEN, tr.BRESP), UVM_MEDIUM)
                            ap.write(tr);
                        end
                    end
                end else begin
                    `uvm_error("MON", $sformatf("Invalid AWLEN value: %0d (exceeds max burst length)", tr.AWLEN))
                end
            end
            
            // Detect read transaction start  
            if (vif.ARVALID && vif.ARREADY && vif.ARESETn) begin
                tr = transaction#()::type_id::create("read_tr");
                tr.OP = transaction#()::read;
                tr.ARADDR = vif.ARADDR;
                tr.ARLEN = vif.ARLEN;
                tr.ARSIZE = vif.ARSIZE;
                
                `uvm_info("MON", $sformatf("Read transaction detected: ADDR=0x%0h, LEN=%0d", 
                         tr.ARADDR, tr.ARLEN), UVM_MEDIUM)
                
                // FIXED: Proper ARLEN validation
                if (tr.ARLEN <= 8'd255) begin  // AXI4 allows 0-255
                    tr.RDATA = new[tr.ARLEN + 1];
                    
                    // Capture read data beat by beat
                    for (int i = 0; i <= tr.ARLEN; i++) begin
                        // Wait for valid data beat
                        do begin
                            @(posedge vif.ACLK);
                        end while (!(vif.RVALID && vif.RREADY) || !vif.ARESETn);
                        
                        if (!vif.ARESETn) break; // Exit if reset
                        
                        tr.RDATA[i] = vif.RDATA;
                        `uvm_info("MON", $sformatf("Captured RDATA[%0d] = 0x%0h", i, vif.RDATA), UVM_HIGH)
                        
                        // Check RLAST signal
                        if (i == tr.ARLEN && !vif.RLAST) begin
                            `uvm_error("MON", "RLAST not asserted on final read beat");
                        end else if (vif.RLAST && i != tr.ARLEN) begin
                            `uvm_warning("MON", $sformatf("RLAST asserted early at beat %0d, expected at beat %0d", 
                                        i, tr.ARLEN));
                            break;
                        end
                    end
                    
                    // Capture final response
                    if (vif.ARESETn) begin
                        tr.RRESP = vif.RRESP;
                        `uvm_info("MON", $sformatf("Read transaction completed: ADDR=0x%0h, LEN=%0d, RRESP=0x%0h", 
                                 tr.ARADDR, tr.ARLEN, tr.RRESP), UVM_MEDIUM)
                        ap.write(tr);
                    end
                end else begin
                    `uvm_error("MON", $sformatf("Invalid ARLEN value: %0d (exceeds max burst length)", tr.ARLEN))
                end
            end
        end
    endtask 
endclass
`endif
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
    
    // DEBUG: Add counters
    int write_transactions_sent = 0;
    int read_transactions_sent = 0;
    int write_transactions_started = 0;
    int read_transactions_started = 0;
    
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
        fork
            monitor_write();
            monitor_read();
        join
    endtask

    task monitor_write();
        transaction tr;
        int i;
        bit current_wlast;
        
        forever begin
            @(posedge vif.ACLK iff vif.ARESETn);
            
            if (vif.AWVALID && vif.AWREADY) begin
                write_transactions_started++;
                `uvm_info("MON_DEBUG", $sformatf("=== WRITE TRANSACTION STARTED #%0d ===", write_transactions_started), UVM_LOW)
                
                tr = transaction#()::type_id::create("write_tr");
                tr.OP = transaction#()::WRITE;
                tr.AWADDR = vif.AWADDR;
                tr.AWLEN = vif.AWLEN;
                tr.AWSIZE = vif.AWSIZE;
                tr.WDATA = new[vif.AWLEN + 1];
                
                // Collect all write data beats
                for (i = 0; i <= vif.AWLEN; i++) begin
                    @(posedge vif.ACLK iff (vif.WVALID && vif.WREADY));
                    tr.WDATA[i] = vif.WDATA;
                    current_wlast = vif.WLAST;
                end
                
                // Wait for response
                @(posedge vif.ACLK iff (vif.BVALID && vif.BREADY));
                tr.BRESP = vif.BRESP;
                
                write_transactions_sent++;
                ap.write(tr);
                `uvm_info("MON_WRITE", $sformatf("Write transaction sent #%0d: ADDR=0x%h, LEN=%0d, RESP=%0d", 
                         write_transactions_sent, tr.AWADDR, tr.AWLEN, tr.BRESP), UVM_LOW)
            end
        end
    endtask

    task monitor_read();
        transaction tr;
        int i;
        bit current_rlast;
        
        forever begin
            @(posedge vif.ACLK iff vif.ARESETn);
            
            if (vif.ARVALID && vif.ARREADY) begin
                read_transactions_started++;
                `uvm_info("MON_DEBUG", $sformatf("=== READ TRANSACTION STARTED #%0d ===", read_transactions_started), UVM_LOW)
                
                tr = transaction#()::type_id::create("read_tr");
                tr.OP = transaction#()::READ;
                tr.ARADDR = vif.ARADDR;
                tr.ARLEN = vif.ARLEN;
                tr.ARSIZE = vif.ARSIZE;
                tr.RDATA = new[vif.ARLEN + 1];
                
                // Collect all read data beats
                for (i = 0; i <= vif.ARLEN; i++) begin
                    @(posedge vif.ACLK iff (vif.RVALID && vif.RREADY));
                    tr.RDATA[i] = vif.RDATA;
                    tr.RRESP = vif.RRESP;
                    current_rlast = vif.RLAST;
                end
                
                read_transactions_sent++;
                ap.write(tr);
                `uvm_info("MON_READ", $sformatf("Read transaction sent #%0d: ADDR=0x%h, LEN=%0d, RESP=%0d", 
                         read_transactions_sent, tr.ARADDR, tr.ARLEN, tr.RRESP), UVM_LOW)
            end
        end
    endtask
    
    function void report_phase(uvm_phase phase);
        `uvm_info("MON_STATS", "=== MONITOR STATISTICS ===", UVM_LOW)
        `uvm_info("MON_STATS", $sformatf("Write transactions started: %0d", write_transactions_started), UVM_LOW)
        `uvm_info("MON_STATS", $sformatf("Write transactions sent:    %0d", write_transactions_sent), UVM_LOW)
        `uvm_info("MON_STATS", $sformatf("Read transactions started:  %0d", read_transactions_started), UVM_LOW)
        `uvm_info("MON_STATS", $sformatf("Read transactions sent:     %0d", read_transactions_sent), UVM_LOW)
        `uvm_info("MON_STATS", "==========================", UVM_LOW)
        
        if (write_transactions_started != write_transactions_sent) begin
            `uvm_warning("MON_STATS", $sformatf("Write transaction mismatch: started=%0d, sent=%0d", 
                        write_transactions_started, write_transactions_sent))
        end
        
        if (read_transactions_started != read_transactions_sent) begin
            `uvm_warning("MON_STATS", $sformatf("Read transaction mismatch: started=%0d, sent=%0d", 
                        read_transactions_started, read_transactions_sent))
        end
    endfunction
endclass
`endif
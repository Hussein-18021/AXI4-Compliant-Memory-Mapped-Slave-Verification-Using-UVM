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
        `uvm_info(get_type_name(), "Monitor run phase - UVM_MEDIUM", UVM_MEDIUM)
        forever 
            begin
                wait(m_cfg.stimulus_sent_e.triggered);
                @(negedge vif.ACLK);
                // @(posedge vif.ACLK);
                `uvm_info(get_type_name(), 
                $sformatf("Monitor: AWREADY=%0b WREADY=%0b | BRESP=%0d BVALID=%0b | ARREADY=%0b | RDATA=0x%0h RRESP=%0d RVALID=%0b RLAST=%0b", 
                          vif.AWREADY, vif.WREADY,
                          vif.BRESP,   vif.BVALID,
                          vif.ARREADY,
                          vif.RDATA,   vif.RRESP, 
                          vif.RVALID,  vif.RLAST), 
                UVM_LOW
            );
            end
    endtask
endclass
`endif


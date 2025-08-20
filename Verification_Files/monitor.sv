`ifndef MONITOR_SVH
`define MONITOR_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;
class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)
    virtual intf vif;
    function new(string name= "monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "Monitor constructor - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Monitor constructor - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Monitor constructor - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Monitor constructor - UVM_FULL", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info(get_type_name(), "Monitor build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Monitor build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Monitor build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Monitor build phase - UVM_FULL", UVM_FULL)

        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif)) 
            begin
                `uvm_fatal(get_full_name(), {"virtual interface must be set for:", ".intf"});
            end
        else 
            begin
                $display ("[Monitor] Corrct accessing of DB!");    
            end
    endfunction

    task run_phase (uvm_phase phase);
        `uvm_info(get_type_name(), "Monitor run phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Monitor run phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Monitor run phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Monitor run phase - UVM_FULL", UVM_FULL)
        forever '
            begin
                //wait(m_cfg.stimulus_sent_e.triggered);
                //@(negedge vif.clk);
                @(posedge vif.clk);
                `uvm_info(get_type_name(), $sformatf("Monitor Results data_out0 = %0d, data_out1 = %0d, valid_out0 = %0d, valid_out1 =%0d", vif. data_out0, vif.data_out1, vif.valid_out0, vif.valid_out1), UVM_LOW);
            end
    endtask
endclass
`endif


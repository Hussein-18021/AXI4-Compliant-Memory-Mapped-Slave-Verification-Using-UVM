`ifndef AGENT_SVH
`define AGENT_SVH
`include "driver.sv"
`include "monitor.sv"
`include "sequencer.sv"
`include "uvm_macros.svh"
import uvm_pkg::*;

class agent extends uvm_agent;
    driver driver_;
    monitor monitor_;
    sequencer sequencer_;
    
    uvm_active_passive_enum  is_active= UVM_ACTIVE;
    
    `uvm_component_utils(agent)
    
    function new(string name= "agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_ = monitor::type_id::create("monitor", this); 
        
        if(!uvm_config_db #(uvm_active_passive_enum)::get(null,"uvm_test_top.env.agent_", "is_active", is_active))  
            `uvm_fatal(get_type_name(), "Failed to find agent enum value ...");
        
        if(is_active==UVM_ACTIVE) begin
            driver_ = driver::type_id::create("driver", this); 
            sequencer_ = sequencer::type_id::create("sequencer", this);
        end

        `uvm_info(get_type_name(), $sformatf ("Agent type is %p", is_active), UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(is_active==UVM_ACTIVE) begin
            driver_.seq_item_port.connect(sequencer_.seq_item_export);
        end
    endfunction 
endclass
`endif


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
        `uvm_info(get_type_name(), "Agent constructor - UVM_LOW verbosity message", UVM_LOW)
        `uvm_info(get_type_name(), "Agent constructor - UVM_MEDIUM verbosity message", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Agent constructor - UVM_HIGH verbosity message", UVM_HIGH)
        `uvm_info(get_type_name(), "Agent constructor - UVM_FULL verbosity message", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_ = monitor::type_id::create("monitor", this); 
        if(!uvm_config_db #(uvm_active_passive_enum)::get(null,"uvm_test_top.env.agent_", "is_active", is_active))  begin
            `uvm_fatal(get_type_name(), "Failed to find agent enum value ...");
        end
        
        if(is_active==UVM_ACTIVE) begin
            driver_ = driver::type_id::create("driver", this); 
            sequencer_ = sequencer::type_id::create("sequencer", this);
        end

        `uvm_info(get_type_name(), "Agent build phase - UVM_LOW verbosity message", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf ("Agent type is %p", is_active), UVM_LOW)
        `uvm_info(get_type_name(), "Agent build phase - UVM_MEDIUM verbosity message", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Agent build phase - UVM_HIGH verbosity message", UVM_HIGH)
        `uvm_info(get_type_name(), "Agent build phase - UVM_FULL verbosity message", UVM_FULL)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(is_active==UVM_ACTIVE) begin
            driver_.seq_item_port.connect(sequencer_.seq_item_export);
        end
        `uvm_info(get_type_name(), "Agent connect phase - UVM_LOW verbosity message", UVM_LOW)
        `uvm_info(get_type_name(), "Agent connect phase - UVM_MEDIUM verbosity message", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Agent connect phase - UVM_HIGH verbosity message", UVM_HIGH)
        `uvm_info(get_type_name(), "Agent connect phase - UVM_FULL verbosity message", UVM_FULL)
    endfunction 
endclass
`endif


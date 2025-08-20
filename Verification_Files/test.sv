`ifndef TEST_SVH
`define TEST_SVH
`include "uvm_macros.svh"
`include "env.sv"
`include "sequence.sv"
import uvm_pkg::*;
class test extends uvm_test;
    env env_;
    _sequence seq;
    `uvm_component_utils(test)
    
    function new(string name= "test", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "Test constructor - UVM_LOW verbosity message", UVM_LOW)
        `uvm_info(get_type_name(), "Test constructor - UVM_MEDIUM verbosity message", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Test constructor - UVM_HIGH verbosity message", UVM_HIGH)
        `uvm_info(get_type_name(), "Test constructor - UVM_FULL verbosity message", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_ = env::type_id::create("env", this); 
        seq = _sequence::type_id::create("seq");
        `uvm_info(get_type_name(), "Test build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Test build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Test build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Test build phase - UVM_FULL", UVM_FULL)
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        fork
            begin
                seq.start(env_.agent_.sequencer_);
                #10ns;
            end
            begin
                `uvm_info(get_type_name(), "Starting sending the sequence", UVM_LOW);
            end
        join
        phase.drop_objection(this);
    endtask
endclass
`endif


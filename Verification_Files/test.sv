`ifndef TEST_SVH
`define TEST_SVH
`include "uvm_macros.svh"
`include "env.sv"
`include "sequence.sv"
`include "common_cfg.sv"
import uvm_pkg::*;
class test extends uvm_test;
    
    common_cfg m_cfg;
    env env_;
    _sequence seq;
    
    `uvm_component_utils(test)
    
    function new(string name= "test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env_ = env::type_id::create("env", this); 
        seq = _sequence::type_id::create("seq");
        m_cfg = common_cfg::type_id::create("m_cfg");
        
        `uvm_info(get_type_name(), "Test build phase - UVM_MEDIUM", UVM_MEDIUM)
        uvm_config_db#(common_cfg)::set(this, "*", "m_cfg", m_cfg);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
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


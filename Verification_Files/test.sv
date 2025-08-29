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
    simple_write_sequence simple_wr_seq;
    simple_read_sequence simple_rd_seq;
    comprehensive_coverage_sequence comprehensive_seq;
    mixed_operation_sequence mixed_seq;
    burst_type_coverage_sequence burst_type_seq;
    address_coverage_sequence addr_seq;
    data_pattern_coverage_sequence pattern_seq;
    handshake_coverage_sequence handshake_seq;
    boundary_memory_sequence mem_violation_seq;

    
    `uvm_component_utils(test)
    
    function new(string name= "test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env_ = env::type_id::create("env", this); 
        m_cfg = common_cfg::type_id::create("m_cfg");
        
        simple_wr_seq = simple_write_sequence::type_id::create("simple_wr_seq");
        simple_rd_seq = simple_read_sequence::type_id::create("simple_rd_seq");
        seq = _sequence::type_id::create("seq");
        
        burst_type_seq = burst_type_coverage_sequence::type_id::create("burst_type_seq");
        addr_seq = address_coverage_sequence::type_id::create("addr_seq");
        pattern_seq = data_pattern_coverage_sequence::type_id::create("pattern_seq");
        handshake_seq = handshake_coverage_sequence::type_id::create("handshake_seq");
        mem_violation_seq = boundary_memory_sequence::type_id::create("mem_violation_seq");

        mixed_seq = mixed_operation_sequence::type_id::create("mixed_seq");
        comprehensive_seq = comprehensive_coverage_sequence::type_id::create("comprehensive_seq");
        
        `uvm_info(get_type_name(), "Test build phase - UVM_MEDIUM", UVM_MEDIUM)
        uvm_config_db#(common_cfg)::set(this, "*", "m_cfg", m_cfg);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_type_name(), "Printing testbench topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "=== STARTING ENHANCED COVERAGE TEST EXECUTION ===", UVM_LOW);
        #100ns;
        
        fork
            begin
                `uvm_info(get_type_name(), "=== PHASE: BASIC FUNCTIONALITY ===", UVM_LOW);
                `uvm_info(get_type_name(), "Running simple write sequence", UVM_LOW);
                simple_wr_seq.start(env_.agent_.sequencer_);
                #50ns;

                `uvm_info(get_type_name(), "Running simple read sequence", UVM_LOW);
                simple_rd_seq.start(env_.agent_.sequencer_);
                #50ns;
                
                `uvm_info(get_type_name(), "=== PHASE: RANDOMIZED TRAFFIC ===", UVM_LOW);
                `uvm_info(get_type_name(), "Running main randomized sequence", UVM_LOW);
                seq.start(env_.agent_.sequencer_);
                #200ns;

                `uvm_info(get_type_name(), "=== PHASE: Running Focused sequences ===", UVM_LOW);

                `uvm_info(get_type_name(), "Running burst_type_seq", UVM_LOW);
                burst_type_seq.start(env_.agent_.sequencer_);
                #200ns;

                `uvm_info(get_type_name(), "Running addr_seq sequence", UVM_LOW);
                addr_seq.start(env_.agent_.sequencer_);
                #200ns;

                `uvm_info(get_type_name(), "Running pattern_seq sequence", UVM_LOW);
                pattern_seq.start(env_.agent_.sequencer_);
                #200ns;

                `uvm_info(get_type_name(), "Running handshake_coverage_sequence", UVM_LOW);
                handshake_seq.start(env_.agent_.sequencer_);
                #200ns;

                `uvm_info(get_type_name(), "Running memory violation sequence", UVM_LOW);
                mem_violation_seq.start(env_.agent_.sequencer_);
                #200ns;
        
                `uvm_info(get_type_name(), "=== PHASE: MIXED TRAFFIC ===", UVM_LOW);
                `uvm_info(get_type_name(), "Running mixed operation sequence", UVM_LOW);
                mixed_seq.start(env_.agent_.sequencer_);
                #200ns;
            
                 `uvm_info(get_type_name(), "=== COMPREHENSIVE COVERAGE SEQUENCE ===", UVM_LOW);
                 comprehensive_seq.start(env_.agent_.sequencer_);
                 #500ns;
            end
            begin
                forever begin
                    @m_cfg.stimulus_sent_e;
                    `uvm_info(get_type_name(), "Stimulus sent event received", UVM_HIGH);
                end
            end
        join_any
        `uvm_info(get_type_name(), "=== ALLOWING TIME FOR FINAL TRANSACTIONS ===", UVM_LOW);
        #500ns;        
        `uvm_info(get_type_name(), "=== ENHANCED COVERAGE TEST EXECUTION COMPLETED ===", UVM_LOW);
        phase.drop_objection(this);
    endtask
    
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "=== ENHANCED COVERAGE TEST COMPLETED ===", UVM_LOW)
        `uvm_info(get_type_name(), "Check coverage report and scoreboard results above", UVM_LOW)
    endfunction
endclass
`endif
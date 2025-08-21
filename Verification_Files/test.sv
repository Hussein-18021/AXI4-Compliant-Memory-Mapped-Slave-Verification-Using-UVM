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
    
    `uvm_component_utils(test)
    
    function new(string name= "test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env_ = env::type_id::create("env", this); 
        
        // Create sequences
        seq = _sequence::type_id::create("seq");
        simple_wr_seq = simple_write_sequence::type_id::create("simple_wr_seq");
        simple_rd_seq = simple_read_sequence::type_id::create("simple_rd_seq");
        
        // Create common configuration
        m_cfg = common_cfg::type_id::create("m_cfg");
        
        `uvm_info(get_type_name(), "Test build phase - UVM_MEDIUM", UVM_MEDIUM)
        
        // Set configuration in database
        uvm_config_db#(common_cfg)::set(this, "*", "m_cfg", m_cfg);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_type_name(), "Printing testbench topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "=== STARTING TEST EXECUTION ===", UVM_LOW);
        
        // Wait a bit for initialization
        #100ns;
        
        fork
            begin
                // Run simple sequences first for debugging
                `uvm_info(get_type_name(), "Starting simple write sequence", UVM_LOW);
                simple_wr_seq.start(env_.agent_.sequencer_);
                
                #50ns;
                
                `uvm_info(get_type_name(), "Starting simple read sequence", UVM_LOW);
                simple_rd_seq.start(env_.agent_.sequencer_);
                
                #50ns;
                
                // Run the main randomized sequence
                `uvm_info(get_type_name(), "Starting main sequence", UVM_LOW);
                seq.start(env_.agent_.sequencer_);
                
                #100ns;
            end
            begin
                // Monitor for configuration events
                forever begin
                    @m_cfg.stimulus_sent_e;
                    `uvm_info(get_type_name(), "Stimulus sent event received", UVM_HIGH);
                end
            end
        join_any
        
        // Allow some time for final transactions to complete
        #200ns;
        
        `uvm_info(get_type_name(), "=== TEST EXECUTION COMPLETED ===", UVM_LOW);
        
        phase.drop_objection(this);
    endtask
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "Test completed - check results above", UVM_LOW)
    endfunction
endclass
`endif


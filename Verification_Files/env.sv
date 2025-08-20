`ifndef ENV_SVH
`define ENV_SVH
`include "uvm_macros.svh"
`include "agent.sv"
`include "scoreboard.sv"
`include "coverage.sv"
import uvm_pkg::*;
class env extends uvm_env;
    agent agent_;
    scoreboard scoreboard_;
    coverage_ coverage__;  
    `uvm_component_utils(env)
    
    function new(string name= "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_ = agent::type_id::create("agent_", this);
        scoreboard_ = scoreboard::type_id::create("scoreboard_", this);
        coverage__ = coverage_::type_id::create("coverage_", this);
        `uvm_info(get_type_name(), "env build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction

    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        agent_.monitor_.ap.connect(scoreboard_.analysis_export);
    endfunction
endclass
`endif


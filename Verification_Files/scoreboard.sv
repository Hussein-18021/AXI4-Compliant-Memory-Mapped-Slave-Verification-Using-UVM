`ifndef scoreboard_SVH
`define scoreboard_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    function new(string name= "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "scoreboard constructor - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "scoreboard constructor - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "scoreboard constructor - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "scoreboard constructor - UVM_FULL", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "scoreboard build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "scoreboard build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "scoreboard build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "scoreboard build phase - UVM_FULL", UVM_FULL)
    endfunction
endclass
`endif
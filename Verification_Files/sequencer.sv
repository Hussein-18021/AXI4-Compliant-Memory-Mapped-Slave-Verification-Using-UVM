`ifndef SEQUENCER_SVH
`define SEQUENCER_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class sequencer extends uvm_sequencer #(transaction);
    `uvm_component_utils(sequencer)
    function new(string name= "sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "Sequencer constructor - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Sequencer constructor - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Sequencer constructor - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Sequencer constructor - UVM_FULL", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Sequencer build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Sequencer build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Sequencer build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Sequencer build phase - UVM_FULL", UVM_FULL)
    endfunction
endclass
`endif

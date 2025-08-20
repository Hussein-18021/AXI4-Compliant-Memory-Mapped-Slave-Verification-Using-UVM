`ifndef SEQUENCER_SVH
`define SEQUENCER_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class sequencer extends uvm_sequencer #(transaction);
    `uvm_component_utils(sequencer)
    function new(string name= "sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Sequencer build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction
endclass
`endif

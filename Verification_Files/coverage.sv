`ifndef Coverage_SVH
`define Coverage_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;
class coverage_ extends uvm_component; // or extends uvm_subscriber #(transaction) -- dont forget to include transaction.sv
    `uvm_component_utils(coverage_)
    function new(string name= "Coverage", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "Coverage constructor - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Coverage constructor - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Coverage constructor - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Coverage constructor - UVM_FULL", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Coverage build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Coverage build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Coverage build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Coverage build phase - UVM_FULL", UVM_FULL)
    endfunction
endclass
`endif

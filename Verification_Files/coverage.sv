`ifndef Coverage_SVH
`define Coverage_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class coverage_ extends uvm_component; // or extends uvm_subscriber #(transaction) -- dont forget to include transaction.sv
    `uvm_component_utils(coverage_)
    uvm_analysis_export #(transaction) analysis_export;
    uvm_tlm_analysis_fifo #(transaction) fifo;
    
    transaction req;
    
    function new(string name= "Coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis export", this);
        fifo = new("fifo", this);
        `uvm_info(get_type_name(), "Coverage build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction

    function void connect_phase (uvm_phase phase);
        analysis_export.connect(fifo.analysis_export);
    endfunction

    task run_phase (uvm_phase phase);
        forever begin
            fifo.get(req);
        end
    endtask
endclass
`endif

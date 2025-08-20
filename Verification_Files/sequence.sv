`ifndef sequence_SVH
`define sequence_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class _sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(_sequence)
    function new(string name= "sequence");
        super.new(name);
    endfunction

    task body();
        transaction req;
        repeat(5) begin
            req = transaction::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask
endclass
`endif
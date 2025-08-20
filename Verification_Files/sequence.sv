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
            req = transaction#(32,16)::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            `uvm_info(get_type_name(), {"Data Randomized:", req.sprint()}, UVM_LOW ) //  req.sprint() → returns a string dump of the transaction fields.
            finish_item(req);

            //Another Style
            /*
            `uvm_do(req); // --> 
            `uvm_do_with (req, {DATA == 'd10;})
            `uvm_info(get_type_name(), {"Data Randomized:", req.sprint()}, UVM_LOW )
            */

            /*
            Difference vs. req.print():
                print() directly prints to the log/console.
                sprint() returns the formatted string (you can concatenate, log selectively, etc.).
            */

        end
    endtask

endclass
`endif
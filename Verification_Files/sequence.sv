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
            req = transaction#()::type_id::create("req");
            start_item(req);

            if (!req.randomize()) 
                begin
                    `uvm_error(get_type_name(), "Failed to randomize transaction")
                end 
            else 
                begin
                    `uvm_info(get_type_name(), $sformatf("Transaction randomized successfully: %s", req.convert2string()), UVM_MEDIUM)
                end
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

// Simple directed sequence for debugging
class simple_write_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(simple_write_sequence)
    
    function new(string name = "simple_write_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        
        `uvm_info(get_type_name(), "Starting simple write sequence", UVM_LOW)
        
        req = transaction#()::type_id::create("simple_write_req");
        start_item(req);
        
        // Create a simple, deterministic write transaction
        req.OP = transaction#()::WRITE;
        req.AWADDR = 16'h0000;
        req.AWLEN = 8'h00;  // Single beat
        req.AWSIZE = 3'b010; // 4 bytes
        req.AWVALID = 1'b1;
        req.WVALID = 1'b1;
        req.BREADY = 1'b1;
        req.test_mode = transaction#()::RANDOM_MODE;
        req.data_pattern = transaction#()::RANDOM_DATA;
        
        // Manually set WDATA
        req.WDATA = new[1];
        req.WDATA[0] = 32'h12345678;
        
        `uvm_info(get_type_name(), $sformatf("Simple write: ADDR=0x%0h, DATA=0x%0h", 
                 req.AWADDR, req.WDATA[0]), UVM_LOW)
        
        finish_item(req);
        
        `uvm_info(get_type_name(), "Simple write sequence completed", UVM_LOW)
    endtask
endclass

// Simple directed read sequence
class simple_read_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(simple_read_sequence)
    
    function new(string name = "simple_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        
        `uvm_info(get_type_name(), "Starting simple read sequence", UVM_LOW)
        
        req = transaction#()::type_id::create("simple_read_req");
        start_item(req);
        
        // Create a simple, deterministic read transaction
        req.OP = transaction#()::read;
        req.ARADDR = 16'h0000;
        req.ARLEN = 8'h00;  // Single beat
        req.ARSIZE = 3'b010; // 4 bytes
        req.ARVALID = 1'b1;
        req.RREADY = 1'b1;
        req.test_mode = transaction#()::RANDOM_MODE;
        req.data_pattern = transaction#()::RANDOM_DATA;
        
        // Initialize empty WDATA for read
        req.WDATA = new[0];
        
        `uvm_info(get_type_name(), $sformatf("Simple read: ADDR=0x%0h", req.ARADDR), UVM_LOW)
        
        finish_item(req);
        
        `uvm_info(get_type_name(), "Simple read sequence completed", UVM_LOW)
    endtask
endclass

`endif
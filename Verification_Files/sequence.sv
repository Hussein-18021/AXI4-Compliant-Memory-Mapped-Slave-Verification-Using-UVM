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
        repeat(300) begin
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
        
        // CRITICAL FIX: Call post_randomize to allocate arrays
        req.post_randomize();
        
        // Now it's safe to modify WDATA
        if (req.WDATA.size() > 0) begin
            req.WDATA[0] = 32'h12345678;
        end
        
        `uvm_info(get_type_name(), $sformatf("Simple write: ADDR=0x%0h, DATA=0x%0h", 
                 req.AWADDR, req.WDATA[0]), UVM_LOW)
        
        finish_item(req);
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
        req.OP = transaction#()::READ; // Changed from read to READ
        req.ARADDR = 16'h0000;
        req.ARLEN = 8'h00;
        req.ARSIZE = 3'b010;
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

class burst_type_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(burst_type_coverage_sequence)
    
    function new(string name = "burst_type_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        transaction#()::burst_type_t burst_types[] = '{
            transaction#()::SINGLE_BEAT,
            transaction#()::SHORT_BURST,
            transaction#()::MEDIUM_BURST,
            transaction#()::LONG_BURST
        };
        transaction#()::op_t operations[] = '{transaction#()::WRITE, transaction#()::READ};
        
        `uvm_info(get_type_name(), "Starting burst type coverage sequence", UVM_LOW)
        
        foreach(operations[op]) begin
            foreach(burst_types[bt]) begin
                req = transaction#()::type_id::create("burst_type_req");
                start_item(req);
                
                req.OP = operations[op];
                req.test_mode = transaction#()::BURST_LENGTH_MODE;
                req.data_pattern = transaction#()::RANDOM_DATA;
                req.burst_type = burst_types[bt];
                
                if (operations[op] == transaction#()::WRITE) 
                    begin
                        req.AWADDR = 16'h0000 + (bt * 256);
                        req.AWSIZE = 3'b010;
                        req.awvalid_value = 1'b1;
                        req.bready_value = 1'b1;
                    end 

                else 
                    begin
                        req.ARADDR = 16'h0000 + (bt * 256);
                        req.ARSIZE = 3'b010;
                        req.arvalid_value = 1'b1;
                        req.rready_value = 1'b1;
                    end
                finish_item(req);
            end
        end
        
        `uvm_info(get_type_name(), "Burst type coverage sequence completed", UVM_LOW)
    endtask
endclass

class handshake_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(handshake_coverage_sequence)
    
    function new(string name = "handshake_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        
        `uvm_info(get_type_name(), "Starting handshake coverage sequence", UVM_LOW)
        
        // Write handshake combinations
        // Normal transaction (all valid)
        req = transaction#()::type_id::create("write_normal_(all valid)");
        start_item(req);
            req.OP = transaction#()::WRITE;
            req.AWADDR = 16'h0000;
            req.AWLEN = 0;  //single burst
            req.AWSIZE = 3'b010;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        
        req = transaction#()::type_id::create("write_resp_ignored");
        start_item(req);
            req.OP = transaction#()::WRITE;
            req.AWADDR = 16'h0004;
            req.AWLEN = 0;
            req.AWSIZE = 3'b010;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b0;
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        
        req = transaction#()::type_id::create("write_aborted");
        start_item(req);
            req.OP = transaction#()::WRITE;
            req.AWADDR = 16'h0008;
            req.AWLEN = 0;
            req.AWSIZE = 3'b010;
            req.awvalid_value = 1'b0;  // No address phase
            req.bready_value = 1'b1;
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        

        req = transaction#()::type_id::create("read_normal");
        start_item(req);
            req.OP = transaction#()::READ;
            req.ARADDR = 16'h0010;
            req.ARLEN = 0;
            req.ARSIZE = 3'b010;
            req.arvalid_value = 1'b1;
            req.rready_value = 1'b1;
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        
        req = transaction#()::type_id::create("read_data_ignored");
        start_item(req);
            req.OP = transaction#()::READ;
            req.ARADDR = 16'h0014;
            req.ARLEN = 0;
            req.ARSIZE = 3'b010;
            req.arvalid_value = 1'b1;
            req.rready_value = 1'b0;  // Not ready for data
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        
        req = transaction#()::type_id::create("read_aborted");
        start_item(req);
            req.OP = transaction#()::READ;
            req.ARADDR = 16'h0018;
            req.ARLEN = 0;
            req.ARSIZE = 3'b010;
            req.arvalid_value = 1'b0;  // No address phase
            req.rready_value = 1'b1;
            req.test_mode = transaction#()::RANDOM_MODE;
            req.burst_type = transaction#()::SINGLE_BEAT;
        finish_item(req);
        `uvm_info(get_type_name(), "Handshake coverage sequence completed", UVM_LOW)
    endtask
endclass

class address_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(address_coverage_sequence)
    
    function new(string name = "address_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        // Address ranges matching RANDOM_MODE constraint: [0:255], [256:511], [512:1023]
        int low_addrs[] = '{0, 64, 128, 192, 255};      // [0:255]
        int mid_addrs[] = '{256, 320, 384, 448, 511};   // [256:511] 
        int high_addrs[] = '{512, 640, 768, 896, 1023}; // [512:1023]
        transaction#()::op_t operations[] = '{transaction#()::WRITE, transaction#()::READ};
        
        `uvm_info(get_type_name(), "Starting address coverage sequence", UVM_LOW)
        
        foreach(operations[op]) begin
            foreach(low_addrs[i]) begin
                req = transaction#()::type_id::create("low_addr_req");
                start_item(req);
                
                req.OP = operations[op];
                req.test_mode = transaction#()::RANDOM_MODE;
                req.data_pattern = transaction#()::RANDOM_DATA;
                req.burst_type = transaction#()::SINGLE_BEAT;
                
                if (operations[op] == transaction#()::WRITE) 
                    begin
                        req.AWADDR = low_addrs[i] << 2; // Convert to byte address
                        req.AWLEN = 0;
                        req.AWSIZE = 3'b010;
                        req.awvalid_value = 1'b1;
                        req.bready_value = 1'b1;
                    end 
                
                else 
                    begin
                        req.ARADDR = low_addrs[i] << 2;
                        req.ARLEN = 0;
                        req.ARSIZE = 3'b010;
                        req.arvalid_value = 1'b1;
                        req.rready_value = 1'b1;
                    end
                finish_item(req);
            end
        end
        `uvm_info(get_type_name(), "Address coverage sequence completed", UVM_LOW)
    endtask
endclass

class data_pattern_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(data_pattern_coverage_sequence)
    
    function new(string name = "data_pattern_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        transaction#()::data_pattern_t patterns[] = '{
            transaction#()::RANDOM_DATA,
            transaction#()::ALL_ZEROS,
            transaction#()::ALL_ONES,
            transaction#()::ALTERNATING_AA,
            transaction#()::ALTERNATING_55
        };
        
        `uvm_info(get_type_name(), "Starting data pattern coverage sequence", UVM_LOW)
        
        foreach(patterns[p]) begin
            req = transaction#()::type_id::create("pattern_req");
            start_item(req);
                req.OP = transaction#()::WRITE;
                req.test_mode = transaction#()::DATA_PATTERN_MODE;
                req.data_pattern = patterns[p];
                req.burst_type = transaction#()::SHORT_BURST;
                req.AWADDR = 16'h0000 + (p * 16);
                req.AWLEN = 2;
                req.AWSIZE = 3'b010;
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                `uvm_info(get_type_name(), $sformatf("Testing data pattern: %s", patterns[p].name()), UVM_MEDIUM)
            finish_item(req);
        end
        
        `uvm_info(get_type_name(), "Data pattern coverage sequence completed", UVM_LOW)
    endtask
endclass

class comprehensive_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(comprehensive_coverage_sequence)
    
    burst_type_coverage_sequence burst_type_seq;
    address_coverage_sequence addr_seq;
    data_pattern_coverage_sequence pattern_seq;
    handshake_coverage_sequence handshake_seq;
    
    function new(string name = "comprehensive_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "=== STARTING COMPREHENSIVE COVERAGE SEQUENCE ===", UVM_LOW)
        
        burst_type_seq = burst_type_coverage_sequence::type_id::create("burst_type_seq");
        addr_seq = address_coverage_sequence::type_id::create("addr_seq");
        pattern_seq = data_pattern_coverage_sequence::type_id::create("pattern_seq");
        handshake_seq = handshake_coverage_sequence::type_id::create("handshake_seq");
        
        `uvm_info(get_type_name(), "Phase 1: Burst Type Coverage", UVM_LOW)
        burst_type_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 2: Address Range Coverage", UVM_LOW)
        addr_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 3: Data Pattern Coverage", UVM_LOW)
        pattern_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 4: Handshake Coverage", UVM_LOW)
        handshake_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "=== COMPREHENSIVE COVERAGE SEQUENCE COMPLETED ===", UVM_LOW)
    endtask
endclass

class mixed_operation_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(mixed_operation_sequence)
    
    int num_transactions = 50;
    
    function new(string name = "mixed_operation_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        
        `uvm_info(get_type_name(), "Starting mixed operation sequence", UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            req = transaction#()::type_id::create($sformatf("mixed_req_%0d", i));
            start_item(req);
            
            // Randomize with updated constraints
            if (!req.randomize() with {
                OP dist {transaction#()::WRITE := 50, transaction#()::READ := 50};
                test_mode dist {
                    transaction#()::RANDOM_MODE := 40,
                    transaction#()::BOUNDARY_CROSSING_MODE := 30,
                    transaction#()::BURST_LENGTH_MODE := 20,
                    transaction#()::DATA_PATTERN_MODE := 10
                };
                burst_type dist {
                    transaction#()::SINGLE_BEAT := 20,
                    transaction#()::SHORT_BURST := 35,
                    transaction#()::MEDIUM_BURST := 25,
                    transaction#()::LONG_BURST := 15
                };
                awvalid_value dist {1 := 90, 0 := 10};
                arvalid_value dist {1 := 90, 0 := 10};
                bready_value dist {1 := 95, 0 := 5};
                rready_value dist {1 := 95, 0 := 5};
            }) begin
                `uvm_error(get_type_name(), $sformatf("Failed to randomize transaction %0d", i))
            end
            
            `uvm_info(get_type_name(), $sformatf("Mixed transaction %0d: %s, burst_type: %s", 
                     i, req.OP.name(), req.burst_type.name()), UVM_HIGH)
            
            finish_item(req);
        end
        
        `uvm_info(get_type_name(), "Mixed operation sequence completed", UVM_LOW)
    endtask
endclass
`endif
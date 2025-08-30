`ifndef sequence_SVH
`define sequence_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
import enumming::*;

class _sequence extends uvm_sequence #(transaction);
    
    `uvm_object_utils(_sequence)
    int num_transactions = 9000;

    function new(string name= "sequence");
        super.new(name);
    endfunction

    task body();
        transaction req;
        repeat(num_transactions) begin
            req = transaction#()::type_id::create("Focused_req");
            start_item(req);

            if (!req.randomize() with {
                OP dist {WRITE := 50, READ := 50};
                
                test_mode dist {
                    RANDOM_MODE := 25,
                    BOUNDARY_CROSSING_MODE := 25,
                    BURST_LENGTH_MODE := 25,
                    DATA_PATTERN_MODE := 25
                };
                
                burst_type dist {
                    SINGLE_BEAT := 25,
                    SHORT_BURST := 25,
                    MEDIUM_BURST := 25,
                    LONG_BURST := 25
                };
                
                data_pattern dist {
                    RANDOM_DATA := 20,
                    ALL_ZEROS := 20,
                    ALL_ONES := 20,
                    ALTERNATING_AA := 20,
                    ALTERNATING_55 := 20
                };
            }) begin
                `uvm_error(get_type_name(), "Failed to randomize transaction")
            end
            
            finish_item(req);
        end

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

    endtask

endclass

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
            req.OP = WRITE;
            req.AWADDR = 16'h0000;
            req.AWLEN = 8'h00;
            req.AWSIZE = 3'b010;
            req.AWVALID = 1'b1;
            req.WVALID = 1'b1;
            req.BREADY = 1'b1;
            req.test_mode = RANDOM_MODE;
            req.data_pattern = RANDOM_DATA;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            
            // Manually allocate and initialize WDATA
            req.WDATA = new[req.AWLEN + 1];
            req.WDATA[0] = 32'hffffffff;
            
            `uvm_info(get_type_name(), $sformatf("Simple write: ADDR=0x%0h, DATA=0x%0h", 
                    req.AWADDR, req.WDATA[0]), UVM_LOW)
        finish_item(req);
    endtask
endclass

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
            req.OP = READ;
            req.ARADDR = 16'h0000;
            req.ARLEN = 8'h00;
            req.ARSIZE = 3'b010;
            req.ARVALID = 1'b1;
            req.RREADY = 1'b1;
            req.test_mode = RANDOM_MODE;
            req.data_pattern = RANDOM_DATA;
            req.arvalid_value = 1'b1;
            req.rready_value = 1'b1;
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
        int burst_lengths_single[] = '{0};
        int burst_lengths_short[] = '{1, 2, 3};
        int burst_lengths_medium[] = '{4, 5, 6, 7, 8};
        int burst_lengths_long[] = '{9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20};
        op_t operations[] = '{WRITE, READ};
        
        `uvm_info(get_type_name(), "Starting comprehensive burst length coverage", UVM_LOW)
        
        foreach(operations[op]) begin
            foreach(burst_lengths_single[i]) begin
                req = transaction#()::type_id::create("single_burst_req");
                start_item(req);
                generate_burst_transaction(req, operations[op], burst_lengths_single[i], 
                                         SINGLE_BEAT);
                finish_item(req);
            end
            
            foreach(burst_lengths_short[i]) begin
                req = transaction#()::type_id::create("short_burst_req");
                start_item(req);
                generate_burst_transaction(req, operations[op], burst_lengths_short[i], 
                                         SHORT_BURST);
                finish_item(req);
            end
            
            foreach(burst_lengths_medium[i]) begin
                req = transaction#()::type_id::create("medium_burst_req");
                start_item(req);
                generate_burst_transaction(req, operations[op], burst_lengths_medium[i], 
                                         MEDIUM_BURST);
                finish_item(req);
            end
            
            foreach(burst_lengths_long[i]) begin
                req = transaction#()::type_id::create("long_burst_req");
                start_item(req);
                generate_burst_transaction(req, operations[op], burst_lengths_long[i], 
                                         LONG_BURST);
                finish_item(req);
            end
        end
        
        `uvm_info(get_type_name(), "Burst length coverage sequence completed", UVM_LOW)
    endtask
    
    function void generate_burst_transaction(transaction req, 
                                           op_t op, 
                                           int len, 
                                           burst_type_t burst_type);
        req.OP = op;
        req.burst_type = burst_type;
        req.test_mode = BURST_LENGTH_MODE;
        req.data_pattern = RANDOM_DATA;
        
        if (op == WRITE) begin
            req.AWLEN = len;
            req.AWADDR = $urandom_range(0, 1000) << 2;
            req.AWSIZE = 3'b010;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            
            // CRITICAL FIX: Manually allocate and generate WDATA
            req.WDATA = new[len + 1];
            req.wvalid_delay = new[len + 1];
            req.wvalid_pattern = new[len + 1];
            
            // Generate data pattern manually
            for (int i = 0; i <= len; i++) begin
                case (req.data_pattern)
                    RANDOM_DATA: req.WDATA[i] = $urandom();
                    ALL_ZEROS: req.WDATA[i] = 32'h00000000;
                    ALL_ONES: req.WDATA[i] = 32'hFFFFFFFF;
                    ALTERNATING_AA: req.WDATA[i] = 32'hAAAAAAAA;
                    ALTERNATING_55: req.WDATA[i] = 32'h55555555;
                endcase
                req.wvalid_delay[i] = 0;
                req.wvalid_pattern[i] = 1'b1;
            end
        end 
        else begin
            req.ARLEN = len;
            req.ARADDR = $urandom_range(0, 1000) << 2;
            req.ARSIZE = 3'b010;
            req.arvalid_value = 1'b1;
            req.rready_value = 1'b1;
            req.WDATA = new[0];
            req.wvalid_delay = new[0];
            req.wvalid_pattern = new[0];
        end
    endfunction
endclass

class handshake_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(handshake_coverage_sequence)
    
    function new(string name = "handshake_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        
        `uvm_info(get_type_name(), "Starting enhanced handshake coverage", UVM_LOW)
        
        // Write handshake scenarios
        req = transaction#()::type_id::create("write_normal");
        start_item(req);
            generate_write_handshake(req, 1'b1, 1'b1, 1'b1, 1'b1);
        finish_item(req);
        
        req = transaction#()::type_id::create("write_resp_ignored");
        start_item(req);
            generate_write_handshake(req, 1'b1, 1'b1, 1'b0, 1'b1);
        finish_item(req);
        
        req = transaction#()::type_id::create("write_awvalid_abort");
        start_item(req);
            generate_write_handshake(req, 1'b0, 1'b1, 1'b1, 1'b0);  
        finish_item(req);
        
        req = transaction#()::type_id::create("write_wvalid_abort");
        start_item(req);
            generate_write_handshake(req, 1'b1, 1'b0, 1'b1, 1'b0);
        finish_item(req);
        
        req = transaction#()::type_id::create("write_both_abort");
        start_item(req);
            generate_write_handshake(req, 1'b0, 1'b0, 1'b1, 1'b0);
        finish_item(req);
        
        // Read handshake scenarios
        req = transaction#()::type_id::create("read_normal");
        start_item(req);
            generate_read_handshake(req, 1'b1, 1'b1);
        finish_item(req);
        
        req = transaction#()::type_id::create("read_data_ignored");
        start_item(req);
            generate_read_handshake(req, 1'b1, 1'b0);
        finish_item(req);
        
        req = transaction#()::type_id::create("read_aborted");
        start_item(req);
            generate_read_handshake(req, 1'b0, 1'b1);
        finish_item(req);
        
        // Test different reset cycles
        for (int reset_val = 0; reset_val <= 3; reset_val++) begin
            req = transaction#()::type_id::create($sformatf("reset_cycle_%0d", reset_val));
            start_item(req);
            
            req.OP = WRITE;
            req.AWLEN = 8'h00;  // Single beat
            req.AWADDR = 16'h0000;
            req.AWSIZE = 3'b010;
            req.reset_cycles = reset_val;
            req.test_mode = RANDOM_MODE;
            req.burst_type = SINGLE_BEAT;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            
            // CRITICAL FIX: Generate WDATA for write transactions
            req.WDATA = new[1];
            req.WDATA[0] = $urandom();
            req.wvalid_delay = new[1];
            req.wvalid_pattern = new[1];
            req.wvalid_delay[0] = 0;
            req.wvalid_pattern[0] = 1'b1;
            
            finish_item(req);
        end
        
        // Test different delay scenarios
        for (int delay_val = 0; delay_val <= 1; delay_val++) begin
            req = transaction#()::type_id::create($sformatf("delay_%0d", delay_val));
            start_item(req);
            
            req.OP = WRITE;
            req.AWLEN = 8'h00;  // Single beat
            req.AWADDR = 16'h0000;
            req.AWSIZE = 3'b010;
            req.awvalid_delay = delay_val;
            req.test_mode = RANDOM_MODE;
            req.burst_type = SINGLE_BEAT;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            
            // CRITICAL FIX: Generate WDATA for write transactions
            req.WDATA = new[1];
            req.WDATA[0] = $urandom();
            req.wvalid_delay = new[1];
            req.wvalid_pattern = new[1];
            req.wvalid_delay[0] = 0;
            req.wvalid_pattern[0] = 1'b1;
            
            finish_item(req);
        end
        
        `uvm_info(get_type_name(), "Enhanced handshake coverage completed", UVM_LOW)
    endtask
    
    function void generate_write_handshake(transaction req, bit awvalid, bit wvalid, bit bready, bit abort_expected);
        req.OP = WRITE;
        req.AWADDR = 16'h0100;
        req.AWLEN = 8'h00;
        req.AWSIZE = 3'b010;
        req.AWVALID = awvalid;
        req.WVALID = wvalid;
        req.BREADY = bready;
        req.awvalid_value = awvalid;
        req.bready_value = bready;
        req.test_mode = RANDOM_MODE;
        req.burst_type = SINGLE_BEAT;
        req.data_pattern = RANDOM_DATA;
        
        // CRITICAL FIX: Generate WDATA for write transactions
        req.WDATA = new[1];
        req.WDATA[0] = $urandom();
        req.wvalid_delay = new[1];
        req.wvalid_pattern = new[1];
        req.wvalid_delay[0] = 0;
        req.wvalid_pattern[0] = wvalid;
    endfunction
    
    function void generate_read_handshake(transaction req, bit arvalid, bit rready);
        req.OP = READ;
        req.ARADDR = 16'h0200;
        req.ARLEN = 8'h00;
        req.ARSIZE = 3'b010;
        req.ARVALID = arvalid;
        req.RREADY = rready;
        req.arvalid_value = arvalid;
        req.rready_value = rready;
        req.test_mode = RANDOM_MODE;
        req.burst_type = SINGLE_BEAT;
        req.WDATA = new[0];
        req.wvalid_delay = new[0];
        req.wvalid_pattern = new[0];
    endfunction
endclass

class address_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(address_coverage_sequence)
    
    function new(string name = "address_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        int low_addrs[$];
        int mid_addrs[$];
        int high_addrs[$];
        op_t operations[] = '{WRITE, READ};
        burst_type_t burst_types[] = '{
            SINGLE_BEAT,
            SHORT_BURST,
            MEDIUM_BURST,
            LONG_BURST
        };
        
        for (int i = 0; i <= 255; i++) low_addrs.push_back(i);
        for (int i = 256; i <= 511; i++) mid_addrs.push_back(i);
        for (int i = 512; i <= 1023; i++) high_addrs.push_back(i);
        
        `uvm_info(get_type_name(), "Starting comprehensive address coverage", UVM_LOW)
        
        foreach(operations[op]) begin
            foreach(burst_types[bt]) begin
                // Low address range
                foreach(low_addrs[i]) begin
                    req = transaction#()::type_id::create("low_addr_req");
                    start_item(req);
                    generate_address_transaction(req, operations[op], low_addrs[i], burst_types[bt]);
                    finish_item(req);
                end
                
                // Mid address range  
                foreach(mid_addrs[i]) begin
                    req = transaction#()::type_id::create("mid_addr_req");
                    start_item(req);
                    generate_address_transaction(req, operations[op], mid_addrs[i], burst_types[bt]);
                    finish_item(req);
                end
                
                // High address range
                foreach(high_addrs[i]) begin
                    req = transaction#()::type_id::create("high_addr_req");
                    start_item(req);
                    generate_address_transaction(req, operations[op], high_addrs[i], burst_types[bt]);
                    finish_item(req);
                end
            end
        end
        
        `uvm_info(get_type_name(), "Comprehensive address coverage completed", UVM_LOW)
    endtask
    
    function void generate_address_transaction(transaction req, 
                                             op_t op, 
                                             int addr, 
                                             burst_type_t burst_type);
        int len;
        req.OP = op;
        req.burst_type = burst_type;
        req.test_mode = RANDOM_MODE;
        req.data_pattern = RANDOM_DATA;
        
        // Determine length based on burst type
        case (burst_type)
            SINGLE_BEAT: len = 0;
            SHORT_BURST: len = $urandom_range(1, 3);
            MEDIUM_BURST: len = $urandom_range(4, 8);
            LONG_BURST: len = $urandom_range(9, 15);
        endcase
        
        if (op == WRITE) begin
            req.AWADDR = addr << 2;
            req.AWLEN = len;
            req.AWSIZE = 3'b010;
            req.awvalid_value = 1'b1;
            req.bready_value = 1'b1;
            
            // CRITICAL FIX: Generate WDATA for write transactions
            req.WDATA = new[len + 1];
            req.wvalid_delay = new[len + 1];
            req.wvalid_pattern = new[len + 1];
            
            for (int i = 0; i <= len; i++) begin
                req.WDATA[i] = $urandom();
                req.wvalid_delay[i] = 0;
                req.wvalid_pattern[i] = 1'b1;
            end
        end else begin
            req.ARADDR = addr << 2;
            req.ARLEN = len;
            req.ARSIZE = 3'b010;
            req.arvalid_value = 1'b1;
            req.rready_value = 1'b1;
            req.WDATA = new[0];
            req.wvalid_delay = new[0];
            req.wvalid_pattern = new[0];
        end
    endfunction
endclass

class data_pattern_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(data_pattern_coverage_sequence)
    
    function new(string name = "data_pattern_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        data_pattern_t patterns[] = '{
            RANDOM_DATA,
            ALL_ZEROS,
            ALL_ONES,
            ALTERNATING_AA,
            ALTERNATING_55
        };
        
        burst_type_t burst_types[] = '{
            SINGLE_BEAT,
            SHORT_BURST,
            MEDIUM_BURST,
            LONG_BURST
        };
        
        `uvm_info(get_type_name(), "Starting complete data pattern coverage", UVM_LOW)
        
        // Test all combinations of patterns and burst types
        foreach(patterns[p]) begin
            foreach(burst_types[bt]) begin
                req = transaction#()::type_id::create($sformatf("pattern_%s_burst_%s", 
                                                   patterns[p].name(), burst_types[bt].name()));
                start_item(req);
                
                req.OP = WRITE;
                req.test_mode = DATA_PATTERN_MODE;
                req.data_pattern = patterns[p];
                req.burst_type = burst_types[bt];
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                req.AWADDR = $urandom_range(0, 1000) << 2;
                req.AWSIZE = 3'b010;
                
                // Determine length based on burst type
                case (burst_types[bt])
                    SINGLE_BEAT: req.AWLEN = 0;
                    SHORT_BURST: req.AWLEN = $urandom_range(1, 3);
                    MEDIUM_BURST: req.AWLEN = $urandom_range(4, 8);
                    LONG_BURST: req.AWLEN = $urandom_range(9, 15);
                endcase
                
                // CRITICAL FIX: Generate WDATA based on pattern
                req.WDATA = new[req.AWLEN + 1];
                req.wvalid_delay = new[req.AWLEN + 1];
                req.wvalid_pattern = new[req.AWLEN + 1];
                
                for (int i = 0; i <= req.AWLEN; i++) begin
                    case (patterns[p])
                        RANDOM_DATA: req.WDATA[i] = $urandom();
                        ALL_ZEROS: req.WDATA[i] = 32'h00000000;
                        ALL_ONES: req.WDATA[i] = 32'hFFFFFFFF;
                        ALTERNATING_AA: req.WDATA[i] = 32'hAAAAAAAA;
                        ALTERNATING_55: req.WDATA[i] = 32'h55555555;
                    endcase
                    req.wvalid_delay[i] = 0;
                    req.wvalid_pattern[i] = 1'b1;
                end
                
                `uvm_info(get_type_name(), $sformatf("Testing pattern: %s with burst: %s", 
                         patterns[p].name(), burst_types[bt].name()), UVM_MEDIUM)
                
                finish_item(req);
            end
        end
        
        `uvm_info(get_type_name(), "Complete data pattern coverage completed", UVM_LOW)
    endtask
endclass

class protocol_response_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(protocol_response_coverage_sequence)
    
    function new(string name = "protocol_response_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        int mode;
        test_mode_t test_modes[] = '{
            RANDOM_MODE,
            BOUNDARY_CROSSING_MODE,
            BURST_LENGTH_MODE,
            DATA_PATTERN_MODE
        };
        
        `uvm_info(get_type_name(), "Starting protocol response coverage", UVM_LOW)
        
        foreach(test_modes[mode]) begin
            // Write with OKAY response
            req = transaction#()::type_id::create("write_okay_resp");
            start_item(req);
                req.OP = WRITE;
                req.test_mode = test_modes[mode];
                req.burst_type = SINGLE_BEAT;
                req.AWLEN = 0;
                req.AWADDR = 16'h0000;
                req.AWSIZE = 3'b010;
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                req.BRESP = 2'b00; // OKAY
                
                // CRITICAL FIX: Generate WDATA
                req.WDATA = new[1];
                req.WDATA[0] = $urandom();
                req.wvalid_delay = new[1];
                req.wvalid_pattern = new[1];
                req.wvalid_delay[0] = 0;
                req.wvalid_pattern[0] = 1'b1;
            finish_item(req);
            
            // Write with SLVERR response
            req = transaction#()::type_id::create("write_slverr_resp");
            start_item(req);
                req.OP = WRITE;
                req.test_mode = test_modes[mode];
                req.burst_type = SINGLE_BEAT;
                req.AWLEN = 0;
                req.AWADDR = 16'h0000;
                req.AWSIZE = 3'b010;
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                req.BRESP = 2'b10; // SLVERR
                
                // CRITICAL FIX: Generate WDATA
                req.WDATA = new[1];
                req.WDATA[0] = $urandom();
                req.wvalid_delay = new[1];
                req.wvalid_pattern = new[1];
                req.wvalid_delay[0] = 0;
                req.wvalid_pattern[0] = 1'b1;
            finish_item(req);
            
            // Read with OKAY response
            req = transaction#()::type_id::create("read_okay_resp");
            start_item(req);
                req.OP = READ;
                req.test_mode = test_modes[mode];
                req.burst_type = SINGLE_BEAT;
                req.ARLEN = 0;
                req.ARADDR = 16'h0000;
                req.ARSIZE = 3'b010;
                req.arvalid_value = 1'b1;
                req.rready_value = 1'b1;
                req.RRESP = 2'b00; // OKAY
                req.WDATA = new[0];
                req.wvalid_delay = new[0];
                req.wvalid_pattern = new[0];
            finish_item(req);
            
            // Read with SLVERR response
            req = transaction#()::type_id::create("read_slverr_resp");
            start_item(req);
                req.OP = READ;
                req.test_mode = test_modes[mode];
                req.burst_type = SINGLE_BEAT;
                req.ARLEN = 0;
                req.ARADDR = 16'h0000;
                req.ARSIZE = 3'b010;
                req.arvalid_value = 1'b1;
                req.rready_value = 1'b1;
                req.RRESP = 2'b10; // SLVERR
                req.WDATA = new[0];
                req.wvalid_delay = new[0];
                req.wvalid_pattern = new[0];
            finish_item(req);
        end
        `uvm_info(get_type_name(), "Protocol response coverage completed", UVM_LOW)
    endtask
endclass

class boundary_memory_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(boundary_memory_sequence)
    
    function new(string name = "boundary_memory_sequence");
        super.new(name);
    endfunction
    
    task body();
        transaction req;
        int base_addr;
        int violation_addr;
        
        `uvm_info(get_type_name(), "Starting boundary crossing and memory violation tests", UVM_LOW)
        
        for (int i = 0; i < 10; i++) begin
            req = transaction#()::type_id::create("boundary_cross_req");
            start_item(req);
            
            req.OP = (i % 2 == 0) ? WRITE : READ;
            req.test_mode = BOUNDARY_CROSSING_MODE;
            req.burst_type = LONG_BURST;
            req.data_pattern = RANDOM_DATA;
            
            base_addr = (4096 * i) - 64; // Close to 4KB boundary
            
            if (req.OP == WRITE) begin
                req.AWADDR = base_addr;
                req.AWLEN = 32; // Long burst to cross boundary
                req.AWSIZE = 3'b010;
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                
                // CRITICAL FIX: Generate WDATA for write transactions
                req.WDATA = new[req.AWLEN + 1];
                req.wvalid_delay = new[req.AWLEN + 1];
                req.wvalid_pattern = new[req.AWLEN + 1];
                
                for (int j = 0; j <= req.AWLEN; j++) begin
                    req.WDATA[j] = $urandom();
                    req.wvalid_delay[j] = 0;
                    req.wvalid_pattern[j] = 1'b1;
                end
            end else begin
                req.ARADDR = base_addr;
                req.ARLEN = 32;
                req.ARSIZE = 3'b010;
                req.arvalid_value = 1'b1;
                req.rready_value = 1'b1;
                req.WDATA = new[0];
                req.wvalid_delay = new[0];
                req.wvalid_pattern = new[0];
            end
            
            finish_item(req);
        end
        
        for (int i = 0; i < 5; i++) begin
            req = transaction#()::type_id::create("memory_violation_req");
            start_item(req);
            
            req.OP = (i % 2 == 0) ? WRITE : READ;
            req.test_mode = BOUNDARY_CROSSING_MODE;
            req.burst_type = LONG_BURST;
            req.data_pattern = RANDOM_DATA;
            
            violation_addr = 1024 + (i * 100); // Beyond valid range
            
            if (req.OP == WRITE) begin
                req.AWADDR = violation_addr << 2;
                req.AWLEN = 16;
                req.AWSIZE = 3'b010;
                req.awvalid_value = 1'b1;
                req.bready_value = 1'b1;
                
                // CRITICAL FIX: Generate WDATA for write transactions
                req.WDATA = new[req.AWLEN + 1];
                req.wvalid_delay = new[req.AWLEN + 1];
                req.wvalid_pattern = new[req.AWLEN + 1];
                
                for (int j = 0; j <= req.AWLEN; j++) begin
                    req.WDATA[j] = $urandom();
                    req.wvalid_delay[j] = 0;
                    req.wvalid_pattern[j] = 1'b1;
                end
            end else begin
                req.ARADDR = violation_addr << 2;
                req.ARLEN = 16;
                req.ARSIZE = 3'b010;
                req.arvalid_value = 1'b1;
                req.rready_value = 1'b1;
                req.WDATA = new[0];
                req.wvalid_delay = new[0];
                req.wvalid_pattern = new[0];
            end
            
            finish_item(req);
        end
        
        `uvm_info(get_type_name(), "Boundary and memory violation tests completed", UVM_LOW)
    endtask
endclass

class comprehensive_coverage_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(comprehensive_coverage_sequence)
    burst_type_coverage_sequence burst_type_seq;
    address_coverage_sequence addr_seq;
    data_pattern_coverage_sequence pattern_seq;
    handshake_coverage_sequence handshake_seq;
    boundary_memory_sequence mem_violation_seq;
    protocol_response_coverage_sequence protocol_seq;

    function new(string name = "comprehensive_coverage_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "=== STARTING COMPREHENSIVE COVERAGE SEQUENCE ===", UVM_LOW)
        
        burst_type_seq = burst_type_coverage_sequence::type_id::create("burst_type_seq");
        addr_seq = address_coverage_sequence::type_id::create("addr_seq");
        pattern_seq = data_pattern_coverage_sequence::type_id::create("pattern_seq");
        handshake_seq = handshake_coverage_sequence::type_id::create("handshake_seq");
        mem_violation_seq = boundary_memory_sequence::type_id::create("mem_violation_seq");
        protocol_seq = protocol_response_coverage_sequence::type_id::create("protocol_seq");

        `uvm_info(get_type_name(), "Phase 1: Burst Type Coverage", UVM_LOW)
        burst_type_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 2: Address Range Coverage", UVM_LOW)
        addr_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 3: Data Pattern Coverage", UVM_LOW)
        pattern_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "Phase 4: Handshake Coverage", UVM_LOW)
        handshake_seq.start(m_sequencer);

        `uvm_info(get_type_name(), "Phase 5: Memory violation Coverage", UVM_LOW)
        mem_violation_seq.start(m_sequencer);

        `uvm_info(get_type_name(), "Phase 6: Protocol specs Coverage", UVM_LOW)
        protocol_seq.start(m_sequencer);
        
        `uvm_info(get_type_name(), "=== COMPREHENSIVE COVERAGE SEQUENCE COMPLETED ===", UVM_LOW)
    endtask
endclass

class mixed_operation_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(mixed_operation_sequence)
    
    int num_transactions = 1000;
    
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
                OP dist {WRITE := 50, READ := 50};
                test_mode dist {
                    RANDOM_MODE := 40,
                    BOUNDARY_CROSSING_MODE := 30,
                    BURST_LENGTH_MODE := 20,
                    DATA_PATTERN_MODE := 10
                };
                burst_type dist {
                    SINGLE_BEAT := 20,
                    SHORT_BURST := 35,
                    MEDIUM_BURST := 25,
                    LONG_BURST := 15
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
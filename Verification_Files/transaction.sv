`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction #(int DATA_WIDTH = 32, int ADDR_WIDTH = 16, int MEMORY_DEPTH = 1024) extends uvm_sequence_item;
    
    typedef enum {READ, WRITE} op_t; // Changed from READ to READ for consistency
    typedef enum {RANDOM_MODE, BOUNDARY_CROSSING_MODE, BURST_LENGTH_MODE, DATA_PATTERN_MODE} test_mode_t;
    typedef enum {RANDOM_DATA, ALL_ZEROS, ALL_ONES, ALTERNATING_AA, ALTERNATING_55} data_pattern_t;
    typedef enum {SINGLE_BEAT, SHORT_BURST, MEDIUM_BURST, LONG_BURST} burst_type_t;
    
    localparam int MEMORY_SIZE_BYTES = MEMORY_DEPTH * 4;
    localparam int MAX_BYTE_ADDR = MEMORY_SIZE_BYTES - 4;

    rand op_t OP;
    rand test_mode_t test_mode;
    rand data_pattern_t data_pattern;
    rand burst_type_t burst_type;
    
    randc logic [ADDR_WIDTH-1:0] AWADDR, ARADDR;
    rand logic [7:0] AWLEN, ARLEN;
    logic [2:0] AWSIZE, ARSIZE;
    
    randc logic [DATA_WIDTH-1:0] WDATA[];  // For burst mode
    logic [DATA_WIDTH-1:0] RDATA[];  //DUT's response
    
    rand logic AWVALID, WVALID, BREADY;
    rand logic ARVALID, RREADY;
    
    rand bit directed_test_mode;
    rand int corner_case_selector;
    rand int reset_cycles;
    rand int awvalid_delay, arvalid_delay;
    rand int wvalid_delay[];
    rand bit awvalid_value, arvalid_value;
    rand bit wvalid_pattern[];
    rand bit bready_value, rready_value; // Changed from bREADy_value, rREADy_value to bready_value, rready_value

    // DUT Response signals
    logic AWREADY, WREADY;              
    logic [1:0] BRESP;                  
    logic BVALID;                       
    logic ARREADY;
    logic [1:0] RRESP;                  
    logic RLAST, RVALID;                

    // EXPECTED VALUES - Including expected WDATA for golden model comparison
    logic expected_AWREADY, expected_WREADY;
    logic [1:0] expected_BRESP;
    logic expected_BVALID;
    logic expected_ARREADY;
    logic [DATA_WIDTH-1:0] expected_RDATA[];
    logic [DATA_WIDTH-1:0] expected_WDATA[];
    logic [1:0] expected_RRESP;
    logic expected_RLAST, expected_RVALID;

    `uvm_object_utils_begin(transaction)
        `uvm_field_enum(op_t, OP, UVM_DEFAULT)
        `uvm_field_enum(test_mode_t, test_mode, UVM_DEFAULT)
        `uvm_field_enum(data_pattern_t, data_pattern, UVM_DEFAULT)
        `uvm_field_enum(burst_type_t, burst_type, UVM_DEFAULT)
        `uvm_field_int(directed_test_mode, UVM_DEFAULT)
        `uvm_field_int(corner_case_selector, UVM_DEFAULT)
        
        `uvm_field_int(AWADDR, UVM_DEFAULT)
        `uvm_field_int(ARADDR, UVM_DEFAULT)
        `uvm_field_int(AWLEN, UVM_DEFAULT)
        `uvm_field_int(ARLEN, UVM_DEFAULT)
        `uvm_field_int(AWSIZE, UVM_DEFAULT)
        `uvm_field_int(ARSIZE, UVM_DEFAULT)
        
        // BURST DATA ARRAYS
        `uvm_field_array_int(WDATA, UVM_DEFAULT)
        `uvm_field_array_int(RDATA, UVM_DEFAULT)
        `uvm_field_array_int(expected_RDATA, UVM_DEFAULT)
        `uvm_field_array_int(expected_WDATA, UVM_DEFAULT)
        
        `uvm_field_int(AWVALID, UVM_DEFAULT)
        `uvm_field_int(WVALID, UVM_DEFAULT)
        `uvm_field_int(BREADY, UVM_DEFAULT)
        `uvm_field_int(ARVALID, UVM_DEFAULT)
        `uvm_field_int(RREADY, UVM_DEFAULT)
        
        `uvm_field_int(reset_cycles, UVM_DEFAULT)
        `uvm_field_int(awvalid_delay, UVM_DEFAULT)
        `uvm_field_int(arvalid_delay, UVM_DEFAULT)
        `uvm_field_array_int(wvalid_delay, UVM_DEFAULT)
        `uvm_field_int(awvalid_value, UVM_DEFAULT)
        `uvm_field_int(arvalid_value, UVM_DEFAULT)
        `uvm_field_array_int(wvalid_pattern, UVM_DEFAULT)
        `uvm_field_int(bready_value, UVM_DEFAULT) // Changed from bREADy_value to bready_value
        `uvm_field_int(rready_value, UVM_DEFAULT) // Changed from rREADy_value to rready_value
        
        // DUT responses
        `uvm_field_int(AWREADY, UVM_DEFAULT)
        `uvm_field_int(WREADY, UVM_DEFAULT)
        `uvm_field_int(BRESP, UVM_DEFAULT)
        `uvm_field_int(BVALID, UVM_DEFAULT)
        `uvm_field_int(ARREADY, UVM_DEFAULT)
        `uvm_field_int(RRESP, UVM_DEFAULT)
        `uvm_field_int(RLAST, UVM_DEFAULT)
        `uvm_field_int(RVALID, UVM_DEFAULT)
        
        // Expected values
        `uvm_field_int(expected_AWREADY, UVM_DEFAULT)
        `uvm_field_int(expected_WREADY, UVM_DEFAULT)
        `uvm_field_int(expected_BRESP, UVM_DEFAULT)
        `uvm_field_int(expected_BVALID, UVM_DEFAULT)
        `uvm_field_int(expected_ARREADY, UVM_DEFAULT)
        `uvm_field_int(expected_RRESP, UVM_DEFAULT)
        `uvm_field_int(expected_RLAST, UVM_DEFAULT)
        `uvm_field_int(expected_RVALID, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "transaction");
        super.new(name);
        
        OP = READ;
        test_mode = RANDOM_MODE;
        data_pattern = RANDOM_DATA;
        burst_type = SINGLE_BEAT;
        directed_test_mode = 0;
        corner_case_selector = 0;
        
        AWADDR = 16'h0000;
        ARADDR = 16'h0000;
        AWLEN = 8'h00;
        ARLEN = 8'h00;
        AWSIZE = 3'b010;
        ARSIZE = 3'b010;
        
        AWVALID = 1'b1;
        WVALID = 1'b1;
        BREADY = 1'b1;
        ARVALID = 1'b1;
        RREADY = 1'b1;
        
        reset_cycles = 0;
        awvalid_delay = 0;
        arvalid_delay = 0;
        awvalid_value = 1;
        arvalid_value = 1;
        bready_value = 1;
        rready_value = 1;
        
        WDATA = new[0];
        RDATA = new[0];
        expected_RDATA = new[0];
        expected_WDATA = new[0];
        wvalid_delay = new[0];
        wvalid_pattern = new[0];
    endfunction

    constraint operation_dist_c {
        OP dist {READ := 40, WRITE := 60};
    }
    
    constraint test_mode_dist_c {
        test_mode dist {
            RANDOM_MODE := 40,
            BOUNDARY_CROSSING_MODE := 30,
            BURST_LENGTH_MODE := 20,
            DATA_PATTERN_MODE := 10
        };
    }
    
    constraint burst_type_dist_c {
        burst_type dist {
            SINGLE_BEAT := 20,
            SHORT_BURST := 35,
            MEDIUM_BURST := 25,
            LONG_BURST := 15
        };
    }
    
    constraint burst_type_c {
        if (burst_type == SINGLE_BEAT) { 
            AWLEN == 0; 
            ARLEN == 0;
        } 
        else if (burst_type == SHORT_BURST) { 
            AWLEN inside {[1:3]};
            ARLEN inside {[1:3]};
        } 
        else if (burst_type == MEDIUM_BURST) { 
            AWLEN inside {[4:8]};
            ARLEN inside {[4:8]};
        } 
        else if (burst_type == LONG_BURST) { 
            AWLEN inside {[9:15]};
            ARLEN inside {[9:15]};
        } 
        else {
            AWLEN inside {[16:20]};
            ARLEN inside {[16:20]};
        }
    }

    constraint addr_range_targeting_c {
        
        if (test_mode == RANDOM_MODE) {
            AWADDR inside {[0:255], [256:511], [512:1023]};
            ARADDR inside {[0:255], [256:511], [512:1023]};
        }
    }

    constraint boundary_targeting_c {

        if (test_mode == BOUNDARY_CROSSING_MODE) {
            if (OP == WRITE) {
                ((AWADDR & 12'hFFF) + ((AWLEN + 1) << AWSIZE)) > 12'hFFF;
            } else {
                ((ARADDR & 12'hFFF) + ((ARLEN + 1) << ARSIZE)) > 12'hFFF;
            }
        } else {
            if (OP == WRITE) {
                ((AWADDR & 12'hFFF) + ((AWLEN + 1) << AWSIZE)) <= 12'hFFF;
            } else {
                ((ARADDR & 12'hFFF) + ((ARLEN + 1) << ARSIZE)) <= 12'hFFF;
            }
        }
    }

    constraint memory_range_c {
        (AWADDR >> 2) < MEMORY_DEPTH;
        ((AWADDR >> 2) + AWLEN) < MEMORY_DEPTH;
        (ARADDR >> 2) < MEMORY_DEPTH;
        ((ARADDR >> 2) + ARLEN) < MEMORY_DEPTH;
    }
    
    constraint addr_alignment_c {
        AWADDR % (1 << AWSIZE) == 0;
        ARADDR % (1 << ARSIZE) == 0;
    }

    constraint data_pattern_dist_c {
        data_pattern dist {
            RANDOM_DATA := 70,
            ALL_ZEROS := 10,
            ALL_ONES := 10,
            ALTERNATING_AA := 5,
            ALTERNATING_55 := 5
        };
    }

    constraint fixed_size_c {
        AWSIZE == 3'b010;
        ARSIZE == 3'b010;
    }
    

    constraint handshake_delay_c {
        awvalid_delay inside {[0:3]};    
        arvalid_delay inside {[0:3]};    
        reset_cycles inside {[1:5]};     
        
        awvalid_value dist {1 := 90, 0 := 10};     
        arvalid_value dist {1 := 90, 0 := 10};     
        bready_value dist {1 := 98, 0 := 2}; // Changed from bREADy_value to bready_value      
        rready_value dist {1 := 95, 0 := 5}; // Changed from rREADy_value to rready_value      
        

    }

    constraint valid_signals_c {
        AWVALID dist {1 := 95, 0 := 5};
        WVALID dist {1 := 95, 0 := 5};
        BREADY dist {1 := 90, 0 := 10};
        ARVALID dist {1 := 95, 0 := 5};
        RREADY dist {1 := 90, 0 := 10};
    }

    constraint corner_case_c {
        if (!directed_test_mode) {
            corner_case_selector inside {[0:15]};
        }
    }

    function void ensure_data_arrays();
        `uvm_info("TRANSACTION_SAFETY", $sformatf("ensure_data_arrays called: OP=%s", OP.name()), UVM_HIGH)
        
        if (OP == WRITE) begin
            int expected_size = AWLEN + 1;
            if (WDATA.size() != expected_size) begin
                `uvm_info("TRANSACTION_SAFETY", $sformatf("Reallocating WDATA: current size=%0d, expected=%0d", 
                        WDATA.size(), expected_size), UVM_MEDIUM)
                WDATA = new[expected_size];
                generate_write_data_pattern();
                
                // Also update expected arrays
                expected_WDATA = new[expected_size];
                for (int i = 0; i < expected_size; i++) begin
                    expected_WDATA[i] = WDATA[i];
                end
            end
        end else if (OP == READ) begin
            int expected_size = ARLEN + 1;
            if (RDATA.size() != expected_size) begin
                `uvm_info("TRANSACTION_SAFETY", $sformatf("Reallocating RDATA: current size=%0d, expected=%0d", 
                        RDATA.size(), expected_size), UVM_MEDIUM)
                RDATA = new[expected_size];
                expected_RDATA = new[expected_size];
                
                // Initialize with default values
                for (int i = 0; i < expected_size; i++) begin
                    RDATA[i] = 32'h00000000;
                    expected_RDATA[i] = 32'h00000000;
                end
            end
        end
    endfunction

    function void post_randomize();
        `uvm_info("TRANSACTION_POST_RAND", $sformatf("post_randomize ENTRY: OP=%s, AWLEN=%0d, ARLEN=%0d", 
                OP.name(), AWLEN, ARLEN), UVM_HIGH)
        
        if (OP == WRITE) begin
            int burst_length = AWLEN + 1;
            
            // Always allocate fresh arrays
            WDATA = new[burst_length];
            expected_WDATA = new[burst_length];
            wvalid_delay = new[burst_length];
            wvalid_pattern = new[burst_length];  // Size based on AWLEN
            
            
            // Set wvalid_pattern based on awvalid_value
            // AXI4 Protocol: If AWVALID=0, no data phase; if AWVALID=1, all data must be sent
            foreach (wvalid_pattern[i]) begin
                if (awvalid_value == 1) begin
                    wvalid_pattern[i] = 1;  // All data beats must be transferred
                end else begin
                    wvalid_pattern[i] = 0;  // No data beats (aborted transaction)
                end
            end
            
            // Generate data pattern
            generate_write_data_pattern();
            
            // Copy to expected
            for (int i = 0; i < burst_length; i++) begin
                expected_WDATA[i] = WDATA[i];
            end
            
            // Clear READ arrays
            RDATA = new[0];
            expected_RDATA = new[0];
            
        end else if (OP == READ) begin
            int burst_length = ARLEN + 1;
            
            // For READ, WDATA should be empty
            WDATA = new[0];
            expected_WDATA = new[0];
            wvalid_delay = new[0];
            wvalid_pattern = new[0];
            
            // Pre-allocate RDATA arrays
            RDATA = new[burst_length];
            expected_RDATA = new[burst_length];
            
            // Initialize with known pattern
            for (int i = 0; i < burst_length; i++) begin
                RDATA[i] = 32'h00000000;
                expected_RDATA[i] = 32'h00000000;
            end
        end
        
        `uvm_info("TRANSACTION_POST_RAND", $sformatf("post_randomize COMPLETE: OP=%s, WDATA[%0d], RDATA[%0d], wvalid_pattern[%0d]", 
                OP.name(), WDATA.size(), RDATA.size(), wvalid_pattern.size()), UVM_HIGH)
    endfunction
    
    function int total_bytes();
        if (OP == WRITE) 
            return (AWLEN + 1) << AWSIZE;
        else
            return (ARLEN + 1) << ARSIZE;
    endfunction

    function int total_write_bytes();
        return (AWLEN + 1) << AWSIZE;
    endfunction
    
    function int total_READ_bytes();
        return (ARLEN + 1) << ARSIZE;
    endfunction

    function bit crosses_4KB_boundary();
        if (OP == WRITE)
            return ((AWADDR & 12'hFFF) + total_write_bytes()) > 12'hFFF;
        else
            return ((ARADDR & 12'hFFF) + total_READ_bytes()) > 12'hFFF;
    endfunction

    function bit exceeds_memory_range();
        case (OP)
            WRITE: return (AWADDR >= MEMORY_SIZE_BYTES) || 
                          ((AWADDR + total_write_bytes()) > MEMORY_SIZE_BYTES);
            READ:  return (ARADDR >= MEMORY_SIZE_BYTES) || 
                          ((ARADDR + total_READ_bytes()) > MEMORY_SIZE_BYTES);
        endcase
    endfunction

    // Generate write data patterns for BURST
    function void generate_write_data_pattern();
        `uvm_info("PATTERN_GEN", $sformatf("Generating %s pattern for %0d beats", 
                 data_pattern.name(), WDATA.size()), UVM_HIGH)
                 
        case (data_pattern)
            RANDOM_DATA: begin
                foreach (WDATA[i]) begin
                    WDATA[i] = $urandom();
                end
            end
            
            ALL_ZEROS: begin
                foreach (WDATA[i]) begin
                    WDATA[i] = 32'h00000000;
                end
            end
            
            ALL_ONES: begin
                foreach (WDATA[i]) begin
                    WDATA[i] = 32'hFFFFFFFF;
                end
            end
            
            ALTERNATING_AA: begin
                foreach (WDATA[i]) begin
                    WDATA[i] = 32'hAAAAAAAA;
                end
            end
            
            ALTERNATING_55: begin
                foreach (WDATA[i]) begin
                    WDATA[i] = 32'h55555555;
                end
            end
        endcase
        
        // Debug: Print generated data
        `uvm_info("PATTERN_GEN", $sformatf("Generated WDATA pattern:"), UVM_HIGH)
        foreach (WDATA[i]) begin
            `uvm_info("PATTERN_GEN", $sformatf("  WDATA[%0d] = 0x%0h", i, WDATA[i]), UVM_HIGH)
        end
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("\n=== Transaction (%s) ===", OP.name());
        s = {s, $sformatf("\nTest Mode: %s", test_mode.name())};
        s = {s, $sformatf("\nBurst Type: %s", burst_type.name())};
        s = {s, $sformatf("\nData Pattern: %s", data_pattern.name())};
        
        if (OP == WRITE) begin
            s = {s, $sformatf("\nWRITE: ADDR=0x%0h, LEN=%0d, SIZE=%0d", AWADDR, AWLEN, AWSIZE)};
            s = {s, $sformatf("\nWDATA[%0d] beats, Total bytes: %0d", WDATA.size(), total_write_bytes())};
            if (WDATA.size() > 0) begin
                s = {s, $sformatf("\nWDATA[0]=0x%0h", WDATA[0])};
                if (WDATA.size() > 1) s = {s, $sformatf(", WDATA[1]=0x%0h", WDATA[1])};
                if (WDATA.size() > 2) s = {s, $sformatf(", ...")};
            end
            s = {s, $sformatf("\nHandshake: AWVALID=%0b, WVALID=%0b, BREADY=%0b", awvalid_value, WVALID, bready_value)}; // Changed from bREADy_value to bready_value
            
            if (!awvalid_value) begin
                s = {s, $sformatf("\nTransaction Scenario: ABORTED - No address phase")};
            end else if (!bready_value) begin // Changed from bREADy_value to bready_value
                s = {s, $sformatf("\nTransaction Scenario: RESPONSE_IGNORED")};
            end else begin
                s = {s, $sformatf("\nTransaction Scenario: NORMAL")};
            end
            
        end else begin
            s = {s, $sformatf("\nREAD: ADDR=0x%0h, LEN=%0d, SIZE=%0d", ARADDR, ARLEN, ARSIZE)};
            s = {s, $sformatf("\nExpecting %0d RDATA beats, Total bytes: %0d", ARLEN+1, total_READ_bytes())};
            s = {s, $sformatf("\nHandshake: ARVALID=%0b, RREADY=%0b", arvalid_value, rready_value)}; // Changed from rREADy_value to rready_value
            
            if (!arvalid_value) begin
                s = {s, $sformatf("\nTransaction Scenario: ABORTED - No address phase")};
            end else if (!rready_value) begin // Changed from rREADy_value to rready_value
                s = {s, $sformatf("\nTransaction Scenario: DATA_IGNORED")};
            end else begin
                s = {s, $sformatf("\nTransaction Scenario: NORMAL")};
            end
        end
        
        s = {s, $sformatf("\n4KB Crossing: %0b, Memory Exceeded: %0b", crosses_4KB_boundary(), exceeds_memory_range())};
        s = {s, $sformatf("\n========================")};
        return s;
    endfunction

endclass
`endif
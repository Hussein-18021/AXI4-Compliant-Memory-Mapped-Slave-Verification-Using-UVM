`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction #(int DATA_WIDTH = 32, int ADDR_WIDTH = 16, int MEMORY_DEPTH = 1024) extends uvm_sequence_item;
    
    typedef enum {read, WRITE} op_t;
    typedef enum {RANDOM_MODE, BOUNDARY_CROSSING_MODE, BURST_LENGTH_MODE, DATA_PATTERN_MODE} test_mode_t;
    typedef enum {RANDOM_DATA, ALL_ZEROS, ALL_ONES, ALTERNATING_AA, ALTERNATING_55} data_pattern_t;
    
    localparam int MEMORY_SIZE_BYTES = MEMORY_DEPTH * 4; // 4KB
    localparam int MAX_BYTE_ADDR = MEMORY_SIZE_BYTES - 4;

    rand op_t OP;
    rand test_mode_t test_mode;
    rand data_pattern_t data_pattern;
    
    rand logic [ADDR_WIDTH-1:0] AWADDR, ARADDR;
    rand logic [7:0] AWLEN, ARLEN;
    logic [2:0] AWSIZE, ARSIZE;
    rand logic [DATA_WIDTH-1:0] WDATA[];
    rand logic AWVALID, WVALID, BREADY;
    rand logic ARVALID, RREADY;
    
    rand bit directed_test_mode;
    rand int corner_case_selector;
    rand int reset_cycles;
    rand int valid_delay;
    rand int ready_delay;

    logic AWREADY, WREADY;              // DUT
    logic [1:0] BRESP;                  // DUT
    logic BVALID;                       // DUT
    logic ARREADY;                      // DUT
    logic [DATA_WIDTH-1:0] RDATA[];     // DUT
    logic [1:0] RRESP;                  // DUT
    logic RLAST, RVALID;                // DUT

    logic expected_AWREADY, expected_WREADY;
    logic [1:0] expected_BRESP;
    logic expected_BVALID;

    logic expected_ARREADY;
    logic [DATA_WIDTH-1:0] expected_RDATA[];
    logic [1:0] expected_RRESP;
    logic expected_RLAST, expected_RVALID;

    // Factory registration
    `uvm_object_utils_begin(transaction)
        
        // Stimulus fields
        `uvm_field_enum(op_t, OP, UVM_DEFAULT)
        `uvm_field_enum(test_mode_t, test_mode, UVM_DEFAULT)
        `uvm_field_enum(data_pattern_t, data_pattern, UVM_DEFAULT)
        `uvm_field_int(directed_test_mode, UVM_DEFAULT)
        `uvm_field_int(corner_case_selector, UVM_DEFAULT)
        
        // Address and control
        `uvm_field_int(AWADDR, UVM_DEFAULT)
        `uvm_field_int(ARADDR, UVM_DEFAULT)
        `uvm_field_int(AWLEN, UVM_DEFAULT)
        `uvm_field_int(ARLEN, UVM_DEFAULT)
        `uvm_field_int(AWSIZE, UVM_DEFAULT)
        `uvm_field_int(ARSIZE, UVM_DEFAULT)
        
        // Data arrays
        `uvm_field_array_int(WDATA, UVM_DEFAULT)
        
        // Valid signals
        `uvm_field_int(AWVALID, UVM_DEFAULT)
        `uvm_field_int(WVALID, UVM_DEFAULT)
        `uvm_field_int(BREADY, UVM_DEFAULT)
        `uvm_field_int(ARVALID, UVM_DEFAULT)
        `uvm_field_int(RREADY, UVM_DEFAULT)
        
        // Timing
        `uvm_field_int(reset_cycles, UVM_DEFAULT)
        `uvm_field_int(valid_delay, UVM_DEFAULT)
        `uvm_field_int(ready_delay, UVM_DEFAULT)
        
        // DUT responses
        `uvm_field_int(AWREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(WREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(BRESP, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(BVALID, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(ARREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_array_int(RDATA, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(RRESP, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(RLAST, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(RVALID, UVM_DEFAULT | UVM_READONLY)
        
        // Expected values (for comparison)
        `uvm_field_int(expected_AWREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_WREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_BRESP, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_BVALID, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_ARREADY, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_array_int(expected_RDATA, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_RRESP, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_RLAST, UVM_DEFAULT | UVM_READONLY)
        `uvm_field_int(expected_RVALID, UVM_DEFAULT | UVM_READONLY)
    `uvm_object_utils_end

    // Constructor
        function new(string name = "transaction");
        super.new(name);
        
        OP = read;
        test_mode = RANDOM_MODE;
        data_pattern = RANDOM_DATA;
        directed_test_mode = 0;
        corner_case_selector = 0;
        
        AWADDR = 16'h0000;
        ARADDR = 16'h0000;
        AWLEN = 8'h00;
        ARLEN = 8'h00;
        AWSIZE = 3'b010; // 4 bytes
        ARSIZE = 3'b010; // 4 bytes
        
        AWVALID = 1'b1;
        WVALID = 1'b1;
        BREADY = 1'b1;
        ARVALID = 1'b1;
        RREADY = 1'b1;
        
        reset_cycles = 0;
        valid_delay = 0;
        ready_delay = 0;
        
        AWREADY = 1'b0;
        WREADY = 1'b0;
        BRESP = 2'b00;
        BVALID = 1'b0;
        ARREADY = 1'b0;
        RRESP = 2'b00;
        RLAST = 1'b0;
        RVALID = 1'b0;
        
        expected_AWREADY = 1'b0;
        expected_WREADY = 1'b0;
        expected_BRESP = 2'b00;
        expected_BVALID = 1'b0;
        expected_ARREADY = 1'b0;
        expected_RRESP = 2'b00;
        expected_RLAST = 1'b0;
        expected_RVALID = 1'b0;
        
        WDATA = new[0];
        RDATA = new[0];
        expected_RDATA = new[0];
    endfunction
    
    constraint operation_dist_c {
        OP dist {read := 50, WRITE := 50};
    }
    
    constraint test_mode_dist_c {
        test_mode dist {
            RANDOM_MODE := 40,
            BOUNDARY_CROSSING_MODE := 25,
            BURST_LENGTH_MODE := 20,
            DATA_PATTERN_MODE := 15
        };
    }
    
    constraint burst_alignment_c {
        // Ensure burst doesn't cross memory boundaries
        (AWADDR % (1 << AWSIZE)) == 0;
        (ARADDR % (1 << ARSIZE)) == 0;
    }

    constraint data_pattern_dist_c {
        data_pattern dist {
            RANDOM_DATA := 60,
            ALL_ZEROS := 15,
            ALL_ONES := 15,
            ALTERNATING_AA := 5,
            ALTERNATING_55 := 5
        };
    }

    constraint fixed_size_c {
        AWSIZE == 3'b010;
        ARSIZE == 3'b010;
    }

    constraint burst_len_c {
        AWLEN inside {[0:15]};
        ARLEN inside {[0:15]};
        
        AWLEN dist {
            0 := 20,        // Single transfer
            [1:3] := 35,    // Short bursts  
            [4:7] := 25,    // Medium bursts
            [8:15] := 20    // Long bursts
        };
        
        ARLEN dist {
            0 := 20,
            [1:3] := 35,
            [4:7] := 25,
            [8:15] := 20
        };
    }

    constraint memory_addr_c {
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
        

        AWADDR inside {[16'h0000:16'h0FFC]};
        ARADDR inside {[16'h0000:16'h0FFC]};
        
        (AWADDR + ((AWLEN + 1) << AWSIZE)) <= MEMORY_SIZE_BYTES;
        (ARADDR + ((ARLEN + 1) << ARSIZE)) <= MEMORY_SIZE_BYTES;
    }

    constraint axi4_boundary_c {
        ((AWADDR >> 12) == ((AWADDR + total_write_bytes() - 1) >> 12));
        ((ARADDR >> 12) == ((ARADDR + total_read_bytes() - 1) >> 12));
    }

    constraint addr_distribution_c {
        AWADDR dist {
            [16'h0000:16'h0554] := 30,
            [16'h0558:16'hAAC] := 30,
            [16'hAB0:16'h0FFC] := 30,
            [16'h0FF0:16'h0FFC] := 10
        };
        
        ARADDR dist {
            [16'h0000:16'h0554] := 30,
            [16'h0558:16'hAAC] := 30,
            [16'hAB0:16'h0FFC] := 30,
            [16'h0FF0:16'h0FFC] := 10
        };
    }

    constraint valid_signals_c {
        AWVALID dist {1 := 95, 0 := 5};
        WVALID dist {1 := 95, 0 := 5};
        BREADY dist {1 := 90, 0 := 10};
        ARVALID dist {1 := 95, 0 := 5};
        RREADY dist {1 := 90, 0 := 10};
    }

    constraint timing_c {
        reset_cycles inside {[0:2]};
        valid_delay inside {[0:3]};
        ready_delay inside {[0:3]};
    }

    constraint corner_case_c {
        if (!directed_test_mode) {
            corner_case_selector inside {[0:15]};
        }
    }

    function void post_randomize();
        if (OP == WRITE) begin
            WDATA = new[AWLEN + 1];
            generate_write_data_pattern();
        end else begin
            WDATA = new[0];
        end
        
        `uvm_info("TRANSACTION", $sformatf("Post-randomize: %s transaction, WDATA[%0d]", 
                  OP.name(), WDATA.size()), UVM_HIGH)
    endfunction
    
    function int total_write_bytes();
        return (AWLEN + 1) << AWSIZE;
    endfunction

    function int total_read_bytes();
        return (ARLEN + 1) << ARSIZE;
    endfunction

    function bit crosses_4KB_boundary();
        logic [15:0] start_4kb, end_4kb;
        
        case (OP)
            WRITE: begin
                start_4kb = AWADDR[15:12];
                end_4kb = (AWADDR + total_write_bytes() - 1) >> 12;
            end
            read: begin
                start_4kb = ARADDR[15:12];
                end_4kb = (ARADDR + total_read_bytes() - 1) >> 12;
            end
        endcase
        
        return (start_4kb != end_4kb);
    endfunction

    function bit exceeds_memory_range();
        case (OP)
            WRITE: return (AWADDR >= MEMORY_SIZE_BYTES) || 
                          ((AWADDR + total_write_bytes()) > MEMORY_SIZE_BYTES);
            read:  return (ARADDR >= MEMORY_SIZE_BYTES) || 
                          ((ARADDR + total_read_bytes()) > MEMORY_SIZE_BYTES);
        endcase
    endfunction

    // Generate write data patterns (STIMULUS only)
    function void generate_write_data_pattern();
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
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("\n=== Transaction (%s) ===", OP.name());
        s = {s, $sformatf("\nTest Mode: %s", test_mode.name())};
        s = {s, $sformatf("\nData Pattern: %s", data_pattern.name())};
        
        if (OP == WRITE) begin
            s = {s, $sformatf("\nWRITE: ADDR=0x%0h, LEN=%0d, SIZE=%0d", AWADDR, AWLEN, AWSIZE)};
            s = {s, $sformatf("\nWDATA[%0d], Total bytes: %0d", WDATA.size(), total_write_bytes())};
            s = {s, $sformatf("\nHandshake: AWVALID=%0b, WVALID=%0b, BREADY=%0b", AWVALID, WVALID, BREADY)};
        end else begin
            s = {s, $sformatf("\nREAD: ADDR=0x%0h, LEN=%0d, SIZE=%0d", ARADDR, ARLEN, ARSIZE)};
            s = {s, $sformatf("\nTotal bytes: %0d", total_read_bytes())};
            s = {s, $sformatf("\nHandshake: ARVALID=%0b, RREADY=%0b", ARVALID, RREADY)};
        end
        
        s = {s, $sformatf("\n4KB Crossing: %0b", crosses_4KB_boundary())};
        s = {s, $sformatf("\n========================")};
        return s;
    endfunction

endclass
`endif
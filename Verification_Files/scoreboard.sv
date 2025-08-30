`ifndef SCOREBOARD_SVH
`define SCOREBOARD_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
import enumming::*;
class scoreboard #(int DATA_WIDTH = 32, int ADDR_WIDTH = 16, int MEMORY_DEPTH = 1024) extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    typedef transaction#(32, 16, 1024) transaction_t;

    uvm_analysis_export #(transaction_t) analysis_export;
    uvm_tlm_analysis_fifo #(transaction_t) fifo;
    virtual intf vif;
    logic [DATA_WIDTH-1:0] golden_memory [MEMORY_DEPTH];

    int error_count, pass_count, total_tests;
    int okay_count, slverr_count;
    int write_count, read_count;
    int boundary_crossing_count, memory_violation_count;
    int aborted_transaction_count, normal_transaction_count;

    function new(string name= "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        
        error_count   = 0;
        pass_count    = 0;
        total_tests   = 0;
        okay_count    = 0;
        slverr_count  = 0;
        write_count   = 0;
        read_count    = 0;
        boundary_crossing_count = 0;
        memory_violation_count = 0;
        aborted_transaction_count = 0;
        normal_transaction_count = 0;

        for (int i = 0; i < 1024; i++) begin
            golden_memory[i] = 32'h00000000;
        end

        analysis_export = new("analysis_export", this);
        fifo = new("fifo", this);
        
        `uvm_info(get_type_name(), "Scoreboard created with transaction_t support", UVM_MEDIUM)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif))
            `uvm_fatal(get_full_name(), "Virtual interface must be set for scoreboard");    
        
        `uvm_info(get_type_name(), "Scoreboard build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        analysis_export.connect(fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        transaction_t req;
        forever begin
            fifo.get(req);
            total_tests++;
            generate_golden_model(req);
            case(req.OP)
                WRITE: begin
                    write_count++;
                    check_write(req);
                end
                READ: begin
                    read_count++;
                    check_read(req);
                end
                default: `uvm_error("SCOREBOARD", $sformatf("Unknown OP: %s", req.OP.name()))
            endcase
        end
    endtask
    
    function void generate_golden_model(transaction_t req);
        `uvm_info("GOLDEN", $sformatf("Generating golden model for %s transaction", req.OP.name()), UVM_HIGH)
        
        case(req.OP)
            WRITE: generate_write_golden(req);
            READ: generate_read_golden(req);
            default: `uvm_error("GOLDEN", $sformatf("Unknown operation: %s", req.OP.name()))
        endcase
    endfunction

    function void generate_write_golden(transaction_t req);
        logic [ADDR_WIDTH-1:0] current_addr;
        logic [31:0] word_addr;
        int burst_size;
        bit boundary_cross, addr_valid;
        
        current_addr = req.AWADDR;
        burst_size = (1 << req.AWSIZE);
        
        // Check for boundary crossing (4KB boundary)
        boundary_cross = ((current_addr & 12'hFFF) + ((req.AWLEN + 1) << req.AWSIZE)) > 12'hFFF;
        
        // Check address validity
        addr_valid = (current_addr >> 2) + (req.AWLEN + 1) < MEMORY_DEPTH;
        
        `uvm_info("GOLDEN_WRITE", $sformatf("ADDR=0x%h, LEN=%0d, boundary_cross=%0b, addr_valid=%0b", 
                current_addr, req.AWLEN, boundary_cross, addr_valid), UVM_MEDIUM)
        
        // Set expected response
        if (!addr_valid || boundary_cross) begin
            req.expected_BRESP = 2'b10; // SLVERR
            slverr_count++;
            if (boundary_cross) boundary_crossing_count++;
            if (!addr_valid) memory_violation_count++;
            aborted_transaction_count++;
        end else begin
            req.expected_BRESP = 2'b00; // OKAY
            okay_count++;
            normal_transaction_count++;
            
            // Update golden memory for valid writes
            foreach(req.WDATA[i]) begin
                word_addr = current_addr >> 2;
                if (word_addr < MEMORY_DEPTH) begin
                    golden_memory[word_addr] = req.WDATA[i];
                    `uvm_info("GOLDEN_WRITE", $sformatf("Writing 0x%h to address 0x%h (word_addr=%0d)", 
                            req.WDATA[i], current_addr, word_addr), UVM_HIGH)
                end
                current_addr += burst_size;
            end
        end
        
        req.expected_BVALID = 1'b1;
        req.expected_AWREADY = 1'b1;
        req.expected_WREADY = 1'b1;
    endfunction

    function void generate_read_golden(transaction_t req);
        logic [ADDR_WIDTH-1:0] current_addr;
        logic [31:0] word_addr;
        int burst_size;
        bit boundary_cross, addr_valid;
        int burst_length;
        
        current_addr = req.ARADDR;
        burst_size = (1 << req.ARSIZE);
        burst_length = req.ARLEN + 1;
        
        // Check for boundary crossing (4KB boundary)
        boundary_cross = ((current_addr & 12'hFFF) + ((req.ARLEN + 1) << req.ARSIZE)) > 12'hFFF;
        
        // Check address validity
        addr_valid = (current_addr >> 2) + (req.ARLEN + 1) < MEMORY_DEPTH;
        
        `uvm_info("GOLDEN_READ", $sformatf("ADDR=0x%h, LEN=%0d, boundary_cross=%0b, addr_valid=%0b", 
                current_addr, req.ARLEN, boundary_cross, addr_valid), UVM_MEDIUM)
        
        // Allocate expected data array
        req.expected_RDATA = new[burst_length];
        
        if (!addr_valid || boundary_cross) begin
            req.expected_RRESP = 2'b10; // SLVERR
            slverr_count++;
            if (boundary_cross) boundary_crossing_count++;
            if (!addr_valid) memory_violation_count++;
            aborted_transaction_count++;
            
            // Fill with zeros for error case
            foreach(req.expected_RDATA[i]) begin
                req.expected_RDATA[i] = 32'h00000000;
            end
        end else begin
            req.expected_RRESP = 2'b00; // OKAY
            okay_count++;
            normal_transaction_count++;
            
            // Read from golden memory for valid reads
            foreach(req.expected_RDATA[i]) begin
                word_addr = current_addr >> 2;
                if (word_addr < MEMORY_DEPTH) begin
                    req.expected_RDATA[i] = golden_memory[word_addr];
                    `uvm_info("GOLDEN_READ", $sformatf("Reading 0x%h from address 0x%h (word_addr=%0d)", 
                            req.expected_RDATA[i], current_addr, word_addr), UVM_HIGH)
                end else begin
                    req.expected_RDATA[i] = 32'h00000000;
                end
                current_addr += burst_size;
            end
        end
        
        req.expected_RVALID = 1'b1;
        req.expected_RLAST = 1'b1;
        req.expected_ARREADY = 1'b1;
    endfunction

    function void check_write(transaction_t req);
        bit pass = 1'b1;
        string error_msg = "";
        
        `uvm_info("CHECK_WRITE", $sformatf("Checking write: ADDR=0x%h, expected_BRESP=%0d, actual_BRESP=%0d", 
                req.AWADDR, req.expected_BRESP, req.BRESP), UVM_MEDIUM)
        
        // Check write response
        if (req.BRESP !== req.expected_BRESP) begin
            pass = 1'b0;
            error_msg = $sformatf("BRESP mismatch: expected=0x%h, actual=0x%h", req.expected_BRESP, req.BRESP);
        end
        
        // Additional checks for handshaking signals would go here if needed
        
        if (pass) begin
            pass_count++;
            `uvm_info("SCOREBOARD", $sformatf("WRITE TEST PASS: ADDR=0x%h, BRESP=%s", 
                    req.AWADDR, decode_resp(req.BRESP)), UVM_LOW)
        end else begin
            error_count++;
            `uvm_error("SCOREBOARD", $sformatf("WRITE TEST FAIL: ADDR=0x%h, %s", req.AWADDR, error_msg))
        end
    endfunction

    function void check_read(transaction_t req);
        bit pass = 1'b1;
        string error_msg = "";
        
        `uvm_info("CHECK_READ", $sformatf("Checking read: ADDR=0x%h, expected_RRESP=%0d, actual_RRESP=%0d", 
                req.ARADDR, req.expected_RRESP, req.RRESP), UVM_MEDIUM)
        
        // Check read response
        if (req.RRESP !== req.expected_RRESP) begin
            pass = 1'b0;
            error_msg = $sformatf("RRESP mismatch: expected=0x%h, actual=0x%h", req.expected_RRESP, req.RRESP);
        end
        
        // Check read data for valid transactions
        if (req.expected_RRESP == 2'b00 && req.RRESP == 2'b00) begin
            if (req.RDATA.size() != req.expected_RDATA.size()) begin
                pass = 1'b0;
                error_msg = {error_msg, $sformatf(" | RDATA size mismatch: expected=%0d, actual=%0d", 
                            req.expected_RDATA.size(), req.RDATA.size())};
            end else begin
                foreach(req.RDATA[i]) begin
                    if (req.RDATA[i] !== req.expected_RDATA[i]) begin
                        pass = 1'b0;
                        error_msg = {error_msg, $sformatf(" | RDATA[%0d] mismatch: expected=0x%h, actual=0x%h", 
                                    i, req.expected_RDATA[i], req.RDATA[i])};
                        break; // Report only first mismatch to avoid log flooding
                    end
                end
            end
        end
        
        if (pass) begin
            pass_count++;
            `uvm_info("SCOREBOARD", $sformatf("READ TEST PASS: ADDR=0x%h, RRESP=%s, beats=%0d", 
                    req.ARADDR, decode_resp(req.RRESP), req.RDATA.size()), UVM_LOW)
        end else begin
            error_count++;
            `uvm_error("SCOREBOARD", $sformatf("READ TEST FAIL: ADDR=0x%h, %s", req.ARADDR, error_msg))
        end
    endfunction

    function string decode_resp(logic [1:0] resp);
        case(resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "UNKNOWN";
        endcase
    endfunction

    function void extract_phase(uvm_phase phase);
        real pass_rate = (total_tests > 0) ? (real'(pass_count) / real'(total_tests)) * 100.0 : 0.0;
        real error_rate = (total_tests > 0) ? (real'(error_count) / real'(total_tests)) * 100.0 : 0.0;
        real write_read_ratio = (total_tests > 0) ? (real'(write_count) / real'(total_tests)) * 100.0 : 0.0;
        real boundary_crossing_rate = (total_tests > 0) ? (real'(boundary_crossing_count) / real'(total_tests)) * 100.0 : 0.0;
        real memory_violation_rate = (total_tests > 0) ? (real'(memory_violation_count) / real'(total_tests)) * 100.0 : 0.0;
        real normal_transaction_rate = (total_tests > 0) ? (real'(normal_transaction_count) / real'(total_tests)) * 100.0 : 0.0;
        
        `uvm_info("SCOREBOARD", "========== FINAL SCOREBOARD REPORT ==========", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL TESTS          = %6d", total_tests), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("PASS COUNT           = %6d (%.1f%%)", pass_count, pass_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("ERROR COUNT          = %6d (%.1f%%)", error_count, error_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", "============================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("WRITE COUNT          = %6d (%.1f%%)", write_count, write_read_ratio), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("READ COUNT           = %6d (%.1f%%)", read_count, 100.0 - write_read_ratio), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("OKAY RESPONSES       = %6d", okay_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SLVERR RESPONSES     = %6d", slverr_count), UVM_LOW)
        `uvm_info("SCOREBOARD", "============================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("NORMAL TRANSACTIONS  = %6d (%.1f%%)", normal_transaction_count, normal_transaction_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("ABORTED TRANSACTIONS = %6d (%.1f%%)", aborted_transaction_count, 100.0 - normal_transaction_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("BOUNDARY CROSSINGS   = %6d (%.1f%%)", boundary_crossing_count, boundary_crossing_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("MEMORY VIOLATIONS    = %6d (%.1f%%)", memory_violation_count, memory_violation_rate), UVM_LOW)
        `uvm_info("SCOREBOARD", "============================================", UVM_LOW)
        
        if (error_count == 0) begin
            `uvm_info("SCOREBOARD", "*** ALL TESTS PASSED! ***", UVM_LOW)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("*** %0d TESTS FAILED ***", error_count))
        end
        
        // Coverage analysis
        if (boundary_crossing_count == 0) begin
            `uvm_warning("SCOREBOARD", "No boundary crossing tests executed - coverage gap")
        end
        
        if (memory_violation_count == 0) begin
            `uvm_warning("SCOREBOARD", "No memory violation tests executed - coverage gap")
        end
        
        if (aborted_transaction_count == 0) begin
            `uvm_warning("SCOREBOARD", "No aborted transaction tests executed - coverage gap")
        end
        
        if (slverr_count == 0) begin
            `uvm_warning("SCOREBOARD", "No SLVERR responses detected - error handling coverage gap")
        end
        
        `uvm_info("SCOREBOARD", "=============================================", UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", "Scoreboard report phase completed", UVM_MEDIUM)
    endfunction

    // Utility functions for external access
    function real get_pass_rate();
        return (total_tests > 0) ? (real'(pass_count) / real'(total_tests)) * 100.0 : 0.0;
    endfunction
    
    function real get_error_rate();
        return (total_tests > 0) ? (real'(error_count) / real'(total_tests)) * 100.0 : 0.0;
    endfunction
    
    function real get_boundary_crossing_rate();
        return (total_tests > 0) ? (real'(boundary_crossing_count) / real'(total_tests)) * 100.0 : 0.0;
    endfunction
    
    function real get_normal_transaction_rate();
        return (total_tests > 0) ? (real'(normal_transaction_count) / real'(total_tests)) * 100.0 : 0.0;
    endfunction

endclass
`endif
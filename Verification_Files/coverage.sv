`ifndef Coverage_SVH
`define Coverage_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;

class coverage_ extends uvm_component;
    `uvm_component_utils(coverage_)
    typedef transaction#(32, 16, 1024) transaction_t;
    uvm_analysis_export #(transaction_t) analysis_export;
    uvm_tlm_analysis_fifo #(transaction_t) fifo;
    transaction_t req;
    
    int total_transactions;
    int write_transactions;
    int read_transactions;
    int error_responses;
    int okay_responses;
    int boundary_crossings;
    int memory_violations;
    int aborted_transactions;
    int normal_transactions;
    
    covergroup burst_coverage_cg with function sample(transaction_t tr);
        burst_len_cp: coverpoint (tr.OP == transaction_t::WRITE ? tr.AWLEN : tr.ARLEN) {
            bins single = {0};                     
            bins short_burst[] = {[1:3]};          
            bins medium_burst[] = {[4:8]};         
            bins long_burst[] = {[9:15]};
        }
        
        burst_type_cp: coverpoint tr.burst_type {
            bins single_beat = {transaction_t::SINGLE_BEAT};
            bins short_burst = {transaction_t::SHORT_BURST};
            bins medium_burst = {transaction_t::MEDIUM_BURST};
            bins long_burst = {transaction_t::LONG_BURST};
        }
    endgroup

    covergroup memory_address_cg with function sample(transaction_t tr);
        addr_combined_cp: coverpoint (tr.OP == transaction_t::WRITE ? (tr.AWADDR >> 2) : (tr.ARADDR >> 2)) {
            bins low_addr[] = {[0:255]};                   
            bins mid_addr[] = {[256:511]};                 
            bins high_addr[] = {[512:1023]};               
        }

        boundary_cross_cp: coverpoint tr.crosses_4KB_boundary() {
            bins no_cross = {0};
            bins crosses = {1};
        }

        memory_bounds_cp: coverpoint tr.exceeds_memory_range() {
            bins within_bounds = {0};
            bins exceeds_bounds = {1};
        }
    endgroup

    covergroup data_patterns_cg with function sample(transaction_t tr);
        data_pattern_cp: coverpoint tr.data_pattern {
            bins random_data = {transaction_t::RANDOM_DATA};
            bins all_zeros = {transaction_t::ALL_ZEROS};
            bins all_ones = {transaction_t::ALL_ONES};
            bins alternating_aa = {transaction_t::ALTERNATING_AA};
            bins alternating_55 = {transaction_t::ALTERNATING_55};
        }
    endgroup

    covergroup handshake_coverage_cg with function sample(transaction_t tr);
        operation_cp: coverpoint tr.OP {
            bins read_ops = {transaction_t::READ};
            bins write_ops = {transaction_t::WRITE};
        }
        
        write_handshake_cp: coverpoint {tr.awvalid_value, tr.bready_value} iff (tr.OP == transaction_t::WRITE) {
            bins normal_transaction = {2'b11};
            bins response_ignored = {2'b10};
            bins aborted_transaction = {2'b00, 2'b01};
        }
        
        read_handshake_cp: coverpoint {tr.arvalid_value, tr.rready_value} iff (tr.OP == transaction_t::READ) {
            bins normal_transaction = {2'b11};
            bins data_ignored = {2'b10};
            bins aborted_transaction = {2'b00, 2'b01};
        }
        
        reset_cycles_cp: coverpoint tr.reset_cycles {
            bins short_reset = {[2:3]};
            bins medium_reset = {[4:5]};
        }
        
        delay_coverage_cp: coverpoint tr.awvalid_delay iff (tr.OP == transaction_t::WRITE) {
            bins no_delay = {0};
            bins short_delay = {[1:2]};
            bins long_delay = {3};
        }
    endgroup

    covergroup protocol_coverage_cg with function sample(transaction_t tr);
        test_mode_cp: coverpoint tr.test_mode {
            bins random_mode = {transaction_t::RANDOM_MODE};
            bins boundary_crossing = {transaction_t::BOUNDARY_CROSSING_MODE};
            bins burst_length = {transaction_t::BURST_LENGTH_MODE};
            bins data_pattern = {transaction_t::DATA_PATTERN_MODE};
        }

        write_resp_cp: coverpoint tr.BRESP iff (tr.OP == transaction_t::WRITE) {
            bins okay = {2'b00};
            bins slverr = {2'b10};
        }
        
        read_resp_cp: coverpoint tr.RRESP iff (tr.OP == transaction_t::READ) {
            bins okay = {2'b00};
            bins slverr = {2'b10};
        }
        
        // Legacy handshake coverage for compatibility
        legacy_write_handshake_cp: coverpoint {tr.AWVALID, tr.WVALID, tr.BREADY} iff (tr.OP == transaction_t::WRITE) {
            bins all_valid = {3'b111};
            bins missing_awvalid = {3'b011};
            bins missing_wvalid = {3'b101};
            bins missing_bready = {3'b110};
        }
        
        legacy_read_handshake_cp: coverpoint {tr.ARVALID, tr.RREADY} iff (tr.OP == transaction_t::READ) {
            bins all_valid = {2'b11};
            bins missing_arvalid = {2'b01};
            bins missing_rready = {2'b10};
        }
    endgroup

    covergroup cross_coverage_cg with function sample(transaction_t tr);
        burst_len_cp: coverpoint (tr.OP == transaction_t::WRITE ? tr.AWLEN : tr.ARLEN) {
            bins single = {0};
            bins short[] = {[1:7]};
            bins med[] = {[8:31]};
            bins long[] = {[32:63]};
        }
        
        addr_range_cp: coverpoint (tr.OP == transaction_t::WRITE ? (tr.AWADDR >> 2) : (tr.ARADDR >> 2)) {
            bins low[] = {[0:255]};
            bins mid[] = {[256:511]};
            bins high[] = {[512:1023]};
        }
        
        operation_cp: coverpoint tr.OP {
            bins reads = {transaction_t::READ};
            bins writes = {transaction_t::WRITE};
        }
        
        burst_type_cp: coverpoint tr.burst_type {
            bins single_beat = {transaction_t::SINGLE_BEAT};
            bins short_burst = {transaction_t::SHORT_BURST};
            bins medium_burst = {transaction_t::MEDIUM_BURST};
            bins long_burst = {transaction_t::LONG_BURST};
        }
        
        data_pattern_cp: coverpoint tr.data_pattern {
            bins random_data = {transaction_t::RANDOM_DATA};
            bins all_zeros = {transaction_t::ALL_ZEROS};
            bins all_ones = {transaction_t::ALL_ONES};
            bins alternating_aa = {transaction_t::ALTERNATING_AA};
            bins alternating_55 = {transaction_t::ALTERNATING_55};
        }
        
        test_mode_cp: coverpoint tr.test_mode {
            bins random_mode = {transaction_t::RANDOM_MODE};
            bins boundary_crossing = {transaction_t::BOUNDARY_CROSSING_MODE};
            bins burst_length = {transaction_t::BURST_LENGTH_MODE};
            bins data_pattern = {transaction_t::DATA_PATTERN_MODE};
        }
        
        burst_addr_cross: cross burst_len_cp, addr_range_cp;
        op_burst_type_cross: cross operation_cp, burst_type_cp;
        op_addr_cross: cross operation_cp, addr_range_cp;
        op_pattern_cross: cross operation_cp, data_pattern_cp;
        mode_pattern_cross: cross test_mode_cp, data_pattern_cp;
        burst_type_mode_cross: cross burst_type_cp, test_mode_cp;
        boundary_op_cross: cross operation_cp, addr_range_cp, burst_len_cp;
    endgroup
    
    function new(string name = "Coverage", uvm_component parent = null);
        super.new(name, parent);
        
        burst_coverage_cg = new();
        memory_address_cg = new();
        data_patterns_cg = new();
        handshake_coverage_cg = new();
        protocol_coverage_cg = new();
        cross_coverage_cg = new();
        
        total_transactions = 0;
        write_transactions = 0;
        read_transactions = 0;
        error_responses = 0;
        okay_responses = 0;
        boundary_crossings = 0;
        memory_violations = 0;
        aborted_transactions = 0;
        normal_transactions = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        fifo = new("fifo", this);
        `uvm_info(get_type_name(), "Coverage build phase", UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        analysis_export.connect(fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            fifo.get(req);
            sample_coverage(req);
        end
    endtask

    function void sample_coverage(transaction_t req);
        total_transactions++;
        
        if (req.OP == transaction_t::WRITE) begin
            write_transactions++;
        end else if (req.OP == transaction_t::READ) begin // Changed from read to READ
            read_transactions++;
        end
        
        // Track transaction scenarios based on handshake values
        if (req.OP == transaction_t::WRITE) begin
            if (req.awvalid_value && req.bready_value) normal_transactions++;
            else aborted_transactions++;
            
            if (req.BRESP == 2'b00) okay_responses++;
            else if (req.BRESP == 2'b10 || req.BRESP == 2'b11) error_responses++;
        end else if (req.OP == transaction_t::READ) begin
            if (req.arvalid_value && req.rready_value) normal_transactions++;
            else aborted_transactions++;
            
            if (req.RRESP == 2'b00) okay_responses++;
            else if (req.RRESP == 2'b10 || req.RRESP == 2'b11) error_responses++;
        end
        
        if (req.crosses_4KB_boundary()) boundary_crossings++;
        if (req.exceeds_memory_range()) memory_violations++;
        
        burst_coverage_cg.sample(req);
        memory_address_cg.sample(req);
        data_patterns_cg.sample(req);
        handshake_coverage_cg.sample(req);
        protocol_coverage_cg.sample(req);
        cross_coverage_cg.sample(req);
        
        `uvm_info("COVERAGE", $sformatf("Sampled %s transaction #%0d: ADDR=0x%0h, LEN=%0d, burst_type=%s, scenario=%s", 
                  req.OP.name(), total_transactions, 
                  (req.OP == transaction_t::WRITE ? req.AWADDR : req.ARADDR),
                  (req.OP == transaction_t::WRITE ? req.AWLEN : req.ARLEN),
                  req.burst_type.name(),
                  get_transaction_scenario(req)), UVM_HIGH)
    endfunction

    function string get_transaction_scenario(transaction_t req);
        if (req.OP == transaction_t::WRITE) begin
            if (!req.awvalid_value) return "ABORTED";
            else if (!req.bready_value) return "RESPONSE_IGNORED";
            else return "NORMAL";
        end else begin
            if (!req.arvalid_value) return "ABORTED";
            else if (!req.rready_value) return "DATA_IGNORED";
            else return "NORMAL";
        end
    endfunction

    function void report_phase(uvm_phase phase);
        real burst_cov, addr_cov, data_cov, handshake_cov, proto_cov, cross_cov, total_cov;
        
        burst_cov = burst_coverage_cg.get_coverage();
        addr_cov = memory_address_cg.get_coverage();
        data_cov = data_patterns_cg.get_coverage();
        handshake_cov = handshake_coverage_cg.get_coverage();
        proto_cov = protocol_coverage_cg.get_coverage();
        cross_cov = cross_coverage_cg.get_coverage();
        total_cov = (burst_cov + addr_cov + data_cov + handshake_cov + proto_cov + cross_cov) / 6.0;
        
        `uvm_info("COVERAGE_REPORT", "============= COVERAGE REPORT =============", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Total Transactions:    %6d", total_transactions), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Write Transactions:    %6d", write_transactions), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Read Transactions:     %6d", read_transactions), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Normal Transactions:   %6d", normal_transactions), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Aborted Transactions:  %6d", aborted_transactions), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("OKAY Responses:        %6d", okay_responses), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Error Responses:       %6d", error_responses), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Boundary Crossings:    %6d", boundary_crossings), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Memory Violations:     %6d", memory_violations), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "==========================================", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Burst Coverage:        %6.2f%%", burst_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Address Coverage:      %6.2f%%", addr_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Data Pattern Coverage: %6.2f%%", data_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Handshake Coverage:    %6.2f%%", handshake_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Protocol Coverage:     %6.2f%%", proto_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Cross Coverage:        %6.2f%%", cross_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "==========================================", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("TOTAL COVERAGE:        %6.2f%%", total_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "==========================================", UVM_LOW)
        
        if (total_cov >= 95.0) begin
            `uvm_info("COVERAGE_REPORT", "*** COVERAGE TARGET ACHIEVED! ***", UVM_LOW)
        end else begin
            `uvm_warning("COVERAGE_REPORT", $sformatf("Coverage target not met (%.2f%% < 95.0%%)", total_cov))
        end
        
        `uvm_info("COVERAGE_REPORT", "========== DETAILED ANALYSIS ==========", UVM_LOW)
        if (burst_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low burst length coverage - consider more burst type variety")
        end
        if (addr_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low address coverage - consider wider address range")
        end
        if (data_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low data pattern coverage - ensure all patterns are tested")
        end
        if (handshake_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low handshake coverage - check transaction scenarios")
        end
        if (proto_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low protocol coverage - check test modes and responses")
        end
        if (cross_cov < 90.0) begin
            `uvm_warning("COVERAGE_REPORT", "Low cross coverage - verify interaction between different features")
        end
    endfunction
    
    function real get_write_read_ratio();
        if (total_transactions == 0) return 0.0;
        return real'(write_transactions) / real'(total_transactions) * 100.0;
    endfunction
    
    function real get_error_rate();
        if (total_transactions == 0) return 0.0;
        return real'(error_responses) / real'(total_transactions) * 100.0;
    endfunction
    
    function real get_boundary_crossing_rate();
        if (total_transactions == 0) return 0.0;
        return real'(boundary_crossings) / real'(total_transactions) * 100.0;
    endfunction
    
    function real get_normal_transaction_rate();
        if (total_transactions == 0) return 0.0;
        return real'(normal_transactions) / real'(total_transactions) * 100.0;
    endfunction
endclass
`endif
`ifndef Coverage_SVH
`define Coverage_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
import enumming::*;
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
        burst_len_cp: coverpoint (tr.OP == WRITE ? tr.AWLEN : tr.ARLEN) {
            bins single = {0};                     
            bins short_burst[] = {[1:3]};          
            bins medium_burst[] = {[4:8]};         
            bins long_burst[] = {[9:15]};
            bins verylongp[] = {[16:20]};
        }
    endgroup

    covergroup memory_address_cg with function sample(transaction_t tr);
        addr_combined_cp: coverpoint (tr.OP == WRITE ? (tr.AWADDR >> 2) : (tr.ARADDR >> 2)) {
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
            bins all_zeros = {32'h0};
            bins all_ones = {32'hFFFFFFFF};
            bins alternating_aa = {32'hAAAAAAAA};
            bins alternating_55 = {32'h55555555};
        }
    endgroup

    covergroup protocol_coverage_cg with function sample(transaction_t tr);
        operation_cp: coverpoint tr.OP {
            bins read_ops = {READ};
            bins write_ops = {WRITE};
        }
        write_resp_cp: coverpoint tr.BRESP iff (tr.OP == WRITE) {
            bins okay = {2'b00};
            bins slverr = {2'b10};
        }
        
        read_resp_cp: coverpoint tr.RRESP iff (tr.OP == READ) {
            bins okay = {2'b00};
            bins slverr = {2'b10};
        }
    endgroup

    covergroup cross_coverage_cg with function sample(transaction_t tr);
        
        addr_range_cp: coverpoint (tr.OP == WRITE ? (tr.AWADDR >> 2) : (tr.ARADDR >> 2)) {
            bins low[] = {[0:255]};
            bins mid[] = {[256:511]};
            bins high[] = {[512:1023]};
        }
        
        operation_cp: coverpoint tr.OP {
            bins reads = {READ};
            bins writes = {WRITE};
        }
        
        data_pattern_cp: coverpoint tr.data_pattern {
            bins all_zeros = {32'h0};
            bins all_ones = {32'hFFFFFFFF};
            bins alternating_aa = {32'hAAAAAAAA};
            bins alternating_55 = {32'h55555555};
        }
        
        op_addr_cross: cross operation_cp, addr_range_cp;
        op_pattern_cross: cross operation_cp, data_pattern_cp;
    endgroup
    
    function new(string name = "Coverage", uvm_component parent = null);
        super.new(name, parent);
        
        burst_coverage_cg = new();
        memory_address_cg = new();
        data_patterns_cg = new();
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
        
        if (req.OP == WRITE) begin
            write_transactions++;
        end else if (req.OP == READ) begin
            read_transactions++;
        end
        
        if (req.OP == WRITE) begin
            if (req.awvalid_value && req.bready_value) 
                normal_transactions++;
            else 
                aborted_transactions++;
            
            if (req.BRESP == 2'b00) 
                okay_responses++;
            else if (req.BRESP == 2'b10 || req.BRESP == 2'b11) 
                error_responses++;
        end 
        else if (req.OP == READ) begin
            if (req.arvalid_value && req.rready_value) 
                normal_transactions++;
            else 
                aborted_transactions++;
            
            if (req.RRESP == 2'b00) 
                okay_responses++;
            else if (req.RRESP == 2'b10 || req.RRESP == 2'b11) 
                error_responses++;
        end
        
        if (req.crosses_4KB_boundary()) boundary_crossings++;
        if (req.exceeds_memory_range()) memory_violations++;
        
        burst_coverage_cg.sample(req);
        memory_address_cg.sample(req);
        data_patterns_cg.sample(req);
        protocol_coverage_cg.sample(req);
        cross_coverage_cg.sample(req);
        
        `uvm_info("COVERAGE", $sformatf("Sampled %s transaction #%0d: ADDR=0x%0h, LEN=%0d, burst_type=%s, scenario=%s", 
                  req.OP.name(), total_transactions, 
                  (req.OP == WRITE ? req.AWADDR : req.ARADDR),
                  (req.OP == WRITE ? req.AWLEN : req.ARLEN),
                  req.burst_type.name(),
                  get_transaction_scenario(req)), UVM_HIGH)
    endfunction

    function string get_transaction_scenario(transaction_t req);
        if (req.OP == WRITE) begin
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
        proto_cov = protocol_coverage_cg.get_coverage();
        cross_cov = cross_coverage_cg.get_coverage();
        total_cov = (burst_cov + addr_cov + data_cov + proto_cov + cross_cov) / 5.0;
        
        `uvm_info("COVERAGE_REPORT", "============= COVERAGE REPORT =============", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Burst Coverage:        %6.2f%%", burst_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Address Coverage:      %6.2f%%", addr_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Data Pattern Coverage: %6.2f%%", data_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Protocol Coverage:     %6.2f%%", proto_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Cross Coverage:        %6.2f%%", cross_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "==========================================", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("TOTAL COVERAGE:        %6.2f%%", total_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "==========================================", UVM_LOW)
        
        if (total_cov == 100.0) begin
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
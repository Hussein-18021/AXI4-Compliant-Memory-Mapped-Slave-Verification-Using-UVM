`ifndef Coverage_SVH
`define Coverage_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;

// Define a typedef for the transaction type to avoid parameterization issues
typedef transaction#(32, 16, 1024) transaction_t;

class coverage_ extends uvm_component;
    `uvm_component_utils(coverage_)
    
    // Use the typedef instead of parameterized class directly
    uvm_analysis_export #(transaction_t) analysis_export;
    uvm_tlm_analysis_fifo #(transaction_t) fifo;
    transaction_t req;
    
    bit addr_valid;
    bit memory_bounds_ok;
    bit crosses_4kb_boundary;
    int burst_len_int;
    int word_addr;

    // Use the typedef for enum references
    transaction_t::op_t operation_type;
    transaction_t::data_pattern_t data_pattern_type;
    transaction_t::test_mode_t test_mode_type;

    covergroup burst_coverage_cg;
        burst_len_cp: coverpoint burst_len_int {
            bins single = {0};                     
            bins short_burst[] = {[1:3]};          
            bins medium_burst[] = {[4:7]};         
            bins long_burst[] = {[8:15]};          
            bins max_burst[] = {[16:255]};         
        }
    endgroup

    covergroup memory_address_cg;
        mem_addr_cp: coverpoint word_addr {
            bins low_addr[] = {[0:341]};                   
            bins mid_addr[] = {[342:681]};                 
            bins high_addr[] = {[682:1023]};               
        }

        boundary_cross_cp: coverpoint crosses_4kb_boundary {
            bins no_cross = {0};
        }

        memory_bounds_cp: coverpoint memory_bounds_ok {
            bins within_bounds = {1};
        }
    endgroup

    covergroup data_patterns_cg;
        data_pattern_cp: coverpoint data_pattern_type {
            bins random_data = {transaction_t::RANDOM_DATA};
            bins all_zeros = {transaction_t::ALL_ZEROS};
            bins all_ones = {transaction_t::ALL_ONES};
            bins alternating_aa = {transaction_t::ALTERNATING_AA};
            bins alternating_55 = {transaction_t::ALTERNATING_55};
        }
    endgroup

    covergroup protocol_coverage_cg;
        burst_type_cp: coverpoint operation_type {
            bins read_ops = {transaction_t::read};
            bins write_ops = {transaction_t::WRITE};
        }
        
        test_mode_cp: coverpoint test_mode_type {
            bins random_mode = {transaction_t::RANDOM_MODE};
            bins boundary_crossing = {transaction_t::BOUNDARY_CROSSING_MODE};
            bins burst_length = {transaction_t::BURST_LENGTH_MODE};
            bins data_pattern = {transaction_t::DATA_PATTERN_MODE};
        }
    endgroup

    covergroup cross_coverage_cg;
        burst_len_cp: coverpoint burst_len_int {
            bins single = {0};
            bins short[] = {[1:3]};
            bins med[] = {[4:7]};
            bins long[] = {[8:15]};
        }
        
        addr_range_cp: coverpoint word_addr {
            bins low[] = {[0:341]};
            bins mid[] = {[342:681]};
            bins high[] = {[682:1023]};
        }
        
        operation_cp: coverpoint operation_type {
            bins reads = {transaction_t::read};
            bins writes = {transaction_t::WRITE};
        }
        
        burst_addr_cross: cross burst_len_cp, addr_range_cp;
        op_burst_cross: cross operation_cp, burst_len_cp;
        op_addr_cross: cross operation_cp, addr_range_cp;
    endgroup
    
    function new(string name = "Coverage", uvm_component parent = null);
        super.new(name, parent);
        burst_coverage_cg = new();
        memory_address_cg = new();
        data_patterns_cg = new();
        protocol_coverage_cg = new();
        cross_coverage_cg = new();
        
        burst_len_int = 0;
        word_addr = 0;
        crosses_4kb_boundary = 0;
        memory_bounds_ok = 1;
        addr_valid = 1;
        operation_type = transaction_t::read;
        data_pattern_type = transaction_t::RANDOM_DATA;
        test_mode_type = transaction_t::RANDOM_MODE;
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
        if (req.OP == transaction_t::read) begin
            burst_len_int = req.ARLEN;
            word_addr = req.ARADDR >> 2;
            operation_type = transaction_t::read;
        end 
        else if (req.OP == transaction_t::WRITE) begin
            burst_len_int = req.AWLEN;
            word_addr = req.AWADDR >> 2;
            operation_type = transaction_t::WRITE;
        end 
        else begin
            `uvm_error("COVERAGE", $sformatf("Unknown operation type: %s", req.OP.name()))
            return;
        end
        
        crosses_4kb_boundary = req.crosses_4KB_boundary();
        memory_bounds_ok = !req.exceeds_memory_range();
        data_pattern_type = req.data_pattern;
        test_mode_type = req.test_mode;
        addr_valid = (word_addr >= 0 && word_addr < 1024);
        
        burst_coverage_cg.sample();
        memory_address_cg.sample();
        data_patterns_cg.sample();
        protocol_coverage_cg.sample();
        cross_coverage_cg.sample();
        
        `uvm_info("COVERAGE", $sformatf("Sampled %s transaction: burst_len=%0d, word_addr=%0d, crosses_4kb=%0b, in_bounds=%0b", 
                  req.OP.name(), burst_len_int, word_addr, crosses_4kb_boundary, memory_bounds_ok), UVM_HIGH)
    endfunction

    function void report_phase(uvm_phase phase);
        real burst_cov, addr_cov, data_cov, proto_cov, cross_cov, total_cov;
        
        burst_cov = burst_coverage_cg.get_coverage();
        addr_cov = memory_address_cg.get_coverage();
        data_cov = data_patterns_cg.get_coverage();
        proto_cov = protocol_coverage_cg.get_coverage();
        cross_cov = cross_coverage_cg.get_coverage();
        total_cov = (burst_cov + addr_cov + data_cov + proto_cov + cross_cov) / 5.0;
        
        `uvm_info("COVERAGE_REPORT", "========== COVERAGE REPORT ==========", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Burst Coverage:        %6.2f%%", burst_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Address Coverage:      %6.2f%%", addr_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Data Pattern Coverage: %6.2f%%", data_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Protocol Coverage:     %6.2f%%", proto_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("Cross Coverage:        %6.2f%%", cross_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "======================================", UVM_LOW)
        `uvm_info("COVERAGE_REPORT", $sformatf("TOTAL COVERAGE:        %6.2f%%", total_cov), UVM_LOW)
        `uvm_info("COVERAGE_REPORT", "======================================", UVM_LOW)
        
        if (total_cov >= 95.0) begin
            `uvm_info("COVERAGE_REPORT", "*** COVERAGE TARGET ACHIEVED! ***", UVM_LOW)
        end 
        else begin
            `uvm_warning("COVERAGE_REPORT", $sformatf("Coverage target not met (%.2f%% < 95.0%%)", total_cov))
        end
    endfunction
endclass
`endif
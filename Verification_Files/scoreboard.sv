`ifndef scoreboard_SVH
`define scoreboard_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;

class scoreboard #(parameter int DATA_WIDTH = 32, parameter int ADDR_WIDTH = 16, parameter int MEMORY_DEPTH = 1024) extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_export #(transaction) analysis_export;
    uvm_tlm_analysis_fifo #(transaction) fifo;
    virtual intf vif;
    
    logic [DATA_WIDTH-1:0] golden_memory [MEMORY_DEPTH];

    int error_count, pass_count, total_tests;
    int okay_count, slverr_count;
    int write_count, read_count;

    function new(string name= "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        
        error_count   = 0;
        pass_count    = 0;
        total_tests   = 0;
        okay_count    = 0;
        slverr_count  = 0;
        write_count   = 0;
        read_count    = 0;

        // Initialize golden memory to known pattern
        for (int i = 0; i < 1024; i++) begin
            golden_memory[i] = 32'h00000000;
        end

        analysis_export = new("analysis_export", this);
        fifo = new("fifo", this);
        
        `uvm_info(get_type_name(), "Scoreboard created", UVM_MEDIUM)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif))
            `uvm_fatal(get_full_name(), "Virtual interface must be set for scoreboard");    
        
        `uvm_info(get_type_name(), "scoreboard build phase - UVM_MEDIUM", UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        analysis_export.connect(fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        transaction#() req;
        forever begin
            fifo.get(req);
            generate_golden_model(req);
            case(req.OP)
                transaction#()::WRITE:   check_write(req);
                transaction#()::read:    check_read(req);
                default:   `uvm_warning("SCOREBOARD", $sformatf("Unknown OP: %s", req.OP))
            endcase
        end
    endtask
    
    function void generate_golden_model(transaction req);
        if (req.OP == transaction#()::WRITE) 
            begin
                generate_write_golden_model(req);
            end 
        else if (req.OP == transaction#()::read) 
            begin
                generate_read_golden_model(req);
            end
        
        `uvm_info("GOLDEN", $sformatf("Golden model generated for %s operation", req.OP.name()), UVM_HIGH)
    endfunction

    function void generate_write_golden_model(transaction req);
        int word_addr;
        int burst_size_bytes;
        
        vif.expected_AWADDR  = req.AWADDR;
        vif.expected_AWLEN   = req.AWLEN;
        vif.expected_AWSIZE  = req.AWSIZE;
        vif.expected_AWVALID = req.AWVALID;
        vif.expected_AWREADY = 1'b1;        
        
        // Store expected data in interface arrays
        vif.expected_WDATA = new[req.WDATA.size()];
        for (int i = 0; i < req.WDATA.size(); i++) 
            begin
                vif.expected_WDATA[i] = req.WDATA[i];
            end
            
        vif.expected_WVALID = req.WVALID;
        vif.expected_WREADY = 1'b1;
        
        if (req.exceeds_memory_range()) 
            begin
                vif.expected_BRESP = 2'b10;
                `uvm_info("GOLDEN", $sformatf("WRITE exceeds memory range - expecting SLVERR"), UVM_MEDIUM)
            end 
        else if (req.crosses_4KB_boundary()) 
            begin
                vif.expected_BRESP = 2'b10;
                `uvm_info("GOLDEN", $sformatf("WRITE crosses 4KB boundary - expecting SLVERR"), UVM_MEDIUM)
            end 
        else 
            begin
                vif.expected_BRESP = 2'b00;
                update_golden_memory_write(req);
                `uvm_info("GOLDEN", $sformatf("WRITE within bounds - expecting OKAY"), UVM_MEDIUM)
            end
        
        vif.expected_BVALID = 1'b1;
        vif.expected_BREADY = req.BREADY;
    endfunction

    function void generate_read_golden_model(transaction req);
        int word_addr;
        
        vif.expected_ARADDR  = req.ARADDR;
        vif.expected_ARLEN   = req.ARLEN;
        vif.expected_ARSIZE  = req.ARSIZE;
        vif.expected_ARVALID = req.ARVALID;
        vif.expected_ARREADY = 1'b1;        
        
        // Store expected data in interface arrays
        vif.expected_RDATA = new[req.ARLEN + 1];
        
        if (req.exceeds_memory_range()) 
            begin
                vif.expected_RRESP = 2'b10;
                for (int i = 0; i <= req.ARLEN; i++) 
                    begin
                        vif.expected_RDATA[i] = 32'hDEADBEEF;  // Error pattern
                    end
                `uvm_info("GOLDEN", $sformatf("READ exceeds memory range - expecting SLVERR"), UVM_MEDIUM)
            end 
        
        else if (req.crosses_4KB_boundary()) 
            begin
                vif.expected_RRESP = 2'b10;  
                for (int i = 0; i <= req.ARLEN; i++) 
                    begin
                        vif.expected_RDATA[i] = 32'hDEADBEEF;
                    end
                `uvm_info("GOLDEN", $sformatf("READ crosses 4KB boundary - expecting SLVERR"), UVM_MEDIUM)
            end 
        
        else 
            begin
                vif.expected_RRESP = 2'b00; 
                generate_golden_memory_read(req);
                `uvm_info("GOLDEN", $sformatf("READ within bounds - expecting OKAY"), UVM_MEDIUM)
            end
        
        vif.expected_RVALID = 1'b1;
        vif.expected_RLAST  = 1'b1;
        vif.expected_RREADY = req.RREADY;
    endfunction

    function void update_golden_memory_write(transaction req);
        int word_addr = req.AWADDR >> 2;
        int burst_length = req.AWLEN + 1;
        int end_word_addr = word_addr + burst_length - 1;
        
        `uvm_info("GOLDEN", $sformatf("Updating golden memory: start_addr=0x%0h, word_addr=%0d, len=%0d", 
                req.AWADDR, word_addr, req.AWLEN), UVM_HIGH)
        
        if (word_addr < 0 || end_word_addr >= MEMORY_DEPTH) begin
            `uvm_error("GOLDEN", $sformatf("Golden memory burst out of bounds: start=%0d, end=%0d, depth=%0d", 
                    word_addr, end_word_addr, MEMORY_DEPTH))
            return;
        end
        
        for (int i = 0; i < burst_length; i++) begin
            golden_memory[word_addr + i] = req.WDATA[i];
            `uvm_info("GOLDEN", $sformatf("golden_memory[%0d] = 0x%0h", 
                    word_addr + i, req.WDATA[i]), UVM_HIGH)
        end
    endfunction

    function void generate_golden_memory_read(transaction req);
        int word_addr = req.ARADDR >> 2;
        
        `uvm_info("GOLDEN", $sformatf("Reading from golden memory: start_addr=0x%0h, word_addr=%0d, len=%0d", 
                  req.ARADDR, word_addr, req.ARLEN), UVM_HIGH)
        
        for (int i = 0; i <= req.ARLEN; i++) begin
            if ((word_addr + i) < 1024) 
                begin  
                    vif.expected_RDATA[i] = golden_memory[word_addr + i];
                    `uvm_info("GOLDEN", $sformatf("expected_RDATA[%0d] = golden_memory[%0d] = 0x%0h", 
                            i, word_addr + i, golden_memory[word_addr + i]), UVM_HIGH)
                end 
            else 
                begin
                    vif.expected_RDATA[i] = 32'h00000000;  // Default for out of bounds
                    `uvm_warning("GOLDEN", $sformatf("Reading beyond golden memory bounds: addr=%0d", word_addr + i))
                end
        end
    endfunction

    task check_write(transaction req);
        bit pass = 1;
        write_count++;

        `uvm_info("CHECK_WRITE", $sformatf("Checking WRITE: ADDR=0x%0h, LEN=%0d, WDATA.size=%0d", 
                  req.AWADDR, req.AWLEN, req.WDATA.size()), UVM_MEDIUM)

        if (vif.expected_AWADDR !== req.AWADDR) begin
            `uvm_error("WRITE_CHECK", $sformatf("AWADDR mismatch: expected=0x%0h actual=0x%0h",
                      vif.expected_AWADDR, req.AWADDR))
            pass = 0;
        end

        if (vif.expected_AWLEN !== req.AWLEN) begin
            `uvm_error("WRITE_CHECK", $sformatf("AWLEN mismatch: expected=%0d actual=%0d",
                      vif.expected_AWLEN, req.AWLEN))
            pass = 0;
        end

        // Compare using interface expected data arrays
        if (vif.expected_WDATA.size() != req.WDATA.size()) 
            begin
                `uvm_error("WRITE_CHECK", $sformatf("WDATA SIZE mismatch: expected=%0d actual=%0d",
                        vif.expected_WDATA.size(), req.WDATA.size()))
                pass = 0;
            end 
        else 
            begin
                for (int i = 0; i < req.WDATA.size(); i++) begin
                    if (vif.expected_WDATA[i] !== req.WDATA[i]) begin
                        `uvm_error("WRITE_CHECK", $sformatf("WDATA[%0d] mismatch: expected=0x%0h actual=0x%0h",
                                i, vif.expected_WDATA[i], req.WDATA[i]))
                        pass = 0;
                    end
                end
            end

        if (vif.expected_BRESP !== req.BRESP) begin
            `uvm_error("WRITE_CHECK", $sformatf("BRESP mismatch: expected=%0b actual=%0b",
                      vif.expected_BRESP, req.BRESP))
            pass = 0;
        end

        if (req.BRESP == 2'b00) 
            okay_count++;
        else if (req.BRESP == 2'b10) 
            slverr_count++;

        update_result(pass, "WRITE");
        
        if (pass) begin
            `uvm_info("WRITE_CHECK", "WRITE transaction PASSED", UVM_MEDIUM)
        end else begin
            `uvm_error("WRITE_CHECK", "WRITE transaction FAILED")
        end
    endtask

    task check_read(transaction req);
        bit pass = 1;
        read_count++;

        `uvm_info("CHECK_READ", $sformatf("Checking READ: ADDR=0x%0h, LEN=%0d, RDATA.size=%0d", 
                  req.ARADDR, req.ARLEN, req.RDATA.size()), UVM_MEDIUM)

        if (vif.expected_ARADDR !== req.ARADDR) begin
            `uvm_error("read_CHECK", $sformatf("ARADDR mismatch: expected=0x%0h actual=0x%0h",
                      vif.expected_ARADDR, req.ARADDR))
            pass = 0;
        end

        if (vif.expected_ARLEN !== req.ARLEN) begin
            `uvm_error("read_CHECK", $sformatf("ARLEN mismatch: expected=%0d actual=%0d",
                      vif.expected_ARLEN, req.ARLEN))
            pass = 0;
        end

        if (vif.expected_RRESP !== req.RRESP) begin
            `uvm_error("read_CHECK", $sformatf("RRESP mismatch: expected=%0b actual=%0b",
                      vif.expected_RRESP, req.RRESP))
            pass = 0;
        end

        // Compare using interface expected data arrays
        if (req.RRESP == 2'b00 && vif.expected_RRESP == 2'b00) 
            begin
                if (vif.expected_RDATA.size() != req.RDATA.size()) 
                    begin
                        `uvm_error("read_CHECK", $sformatf("RDATA size mismatch: expected=%0d actual=%0d",
                                vif.expected_RDATA.size(), req.RDATA.size()))
                        pass = 0;
                    end 
                else 
                    begin
                        for (int i = 0; i < req.RDATA.size(); i++) begin
                            if (vif.expected_RDATA[i] !== req.RDATA[i]) begin
                                `uvm_error("read_CHECK", $sformatf("RDATA[%0d] mismatch: expected=0x%0h actual=0x%0h",
                                        i, vif.expected_RDATA[i], req.RDATA[i]))
                                pass = 0;
                            end
                        end
                    end
            end

        if (req.RRESP == 2'b00) 
            okay_count++;
        else if (req.RRESP == 2'b10) 
            slverr_count++;

        update_result(pass, "READ");
        
        if (pass) begin
            `uvm_info("read_CHECK", "READ transaction PASSED", UVM_MEDIUM)
        end else begin
            `uvm_error("read_CHECK", "READ transaction FAILED")
        end
    endtask

    function void update_result(bit pass, string op);
        total_tests++;
        if(pass) begin
            pass_count++;
            `uvm_info("SCOREBOARD", $sformatf("%s TEST PASS (Total: %0d/%0d)", op, pass_count, total_tests), UVM_LOW)
        end else begin
            error_count++;
            `uvm_error("SCOREBOARD", $sformatf("%s TEST FAIL (Errors: %0d/%0d)", op, error_count, total_tests))
        end
    endfunction

    function void extract_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", "=== FINAL SCOREBOARD REPORT ===", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL TESTS   = %0d", total_tests), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("PASS COUNT    = %0d", pass_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("ERROR COUNT   = %0d", error_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("WRITE COUNT   = %0d", write_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("READ COUNT    = %0d", read_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("OKAY COUNT    = %0d", okay_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SLVERR COUNT  = %0d", slverr_count), UVM_LOW)
        
        if (error_count == 0) begin
            `uvm_info("SCOREBOARD", "*** ALL TESTS PASSED! ***", UVM_LOW)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("*** %0d TESTS FAILED ***", error_count))
        end
        `uvm_info("SCOREBOARD", "==============================", UVM_LOW)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", "Report phase completed", UVM_MEDIUM)
    endfunction

endclass
`endif
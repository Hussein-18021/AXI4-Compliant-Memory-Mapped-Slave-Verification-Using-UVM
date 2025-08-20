`ifndef scoreboard_SVH
`define scoreboard_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    uvm_analysis_export #(transaction) analysis_export;
    uvm_tlm_analysis_fifo #(transaction) fifo;
    virtual intf vif;

    int error_count, pass_count, total_tests;
    int okay_count, slverr_count;

    function new(string name= "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        
        error_count   = 0;
        pass_count    = 0;
        total_tests   = 0;
        okay_count    = 0;
        slverr_count  = 0;

        analysis_export = new("analysis_export", this);
        fifo = new("fifo", this);
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
        transaction req;
        forever begin
            fifo.get(req);
            case(req.OP)
                transaction#(32,16)::WRITE:   check_write(req);
                transaction#(32,16)::READ:    check_read(req);
                default:   `uvm_warning("SCOREBOARD", $sformatf("Unknown OP: %s", req.OP))
            endcase
        end
    endtask

    // ==============================
    // WRITE checking
    // ==============================
    task check_write(transaction req);
        bit pass = 1;

        // AW channel
        if (req.expected_awaddr !== req.actual_awaddr) begin
            `uvm_error("WRITE", $sformatf("AWADDR mismatch: exp=0x%0h act=0x%0h",
                        req.expected_awaddr, req.actual_awaddr))
            pass = 0;
        end

        // WDATA
        if (req.expected_wdata !== req.actual_wdata) begin
            `uvm_error("WRITE", $sformatf("WDATA mismatch: exp=0x%0h act=0x%0h",
                        req.expected_wdata, req.actual_wdata))
            pass = 0;
        end

        // BRESP check
        if (req.expected_bresp !== req.actual_bresp) begin
            `uvm_error("WRITE", $sformatf("BRESP mismatch: exp=0x%0h act=0x%0h",
                        req.expected_bresp, req.actual_bresp))
            pass = 0;
        end

        // Count OKAY / SLVERR
        if (req.actual_bresp == 2'b00) // AXI4: OKAY
            okay_count++;
        else if (req.actual_bresp == 2'b10) // AXI4: SLVERR
            slverr_count++;

        update_result(pass, "WRITE");
    endtask

    // ==============================
    // READ checking
    // ==============================
    task check_read(transaction req);
        bit pass = 1;

        // AR channel
        if (req.expected_araddr !== req.actual_araddr) begin
            `uvm_error("READ", $sformatf("ARADDR mismatch: exp=0x%0h act=0x%0h",
                        req.expected_araddr, req.actual_araddr))
            pass = 0;
        end

        // RDATA
        if (req.expected_rdata !== req.actual_rdata) begin
            `uvm_error("READ", $sformatf("RDATA mismatch: exp=0x%0h act=0x%0h",
                        req.expected_rdata, req.actual_rdata))
            pass = 0;
        end

        // RRESP check
        if (req.expected_rresp !== req.actual_rresp) begin
            `uvm_error("READ", $sformatf("RRESP mismatch: exp=0x%0h act=0x%0h",
                        req.expected_rresp, req.actual_rresp))
            pass = 0;
        end

        // Count OKAY / SLVERR
        if (req.actual_rresp == 2'b00)
            okay_count++;
        else if (req.actual_rresp == 2'b10)
            slverr_count++;

        update_result(pass, "READ");
    endtask

    function void update_result(bit pass, string op);
        if(pass) begin
            pass_count++;
            `uvm_info("SCOREBOARD", {op, " TEST PASS"}, UVM_LOW)
        end else begin
            error_count++;
            `uvm_error("SCOREBOARD", {op, " TEST FAIL"})
        end
    endfunction

    function void extract_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("TOTAL TESTS   = %0d", total_tests), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("PASS COUNT    = %0d", pass_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("ERROR COUNT   = %0d", error_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("OKAY COUNT    = %0d", okay_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("SLVERR COUNT  = %0d", slverr_count), UVM_LOW)
    endfunction

endclass
`endif
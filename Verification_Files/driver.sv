`ifndef DRIVER_SVH
`define DRIVER_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
`include "common_cfg.sv"
import uvm_pkg::*;

typedef transaction#(32, 16, 1024) transaction_t;

class driver extends uvm_driver #(transaction_t);
    
    `uvm_component_utils(driver)
    
    virtual intf vif;
    common_cfg m_cfg;

    int total_write_transactions = 0;
    int total_read_transactions = 0;
    int total_write_beats = 0;
    int total_read_beats = 0;
    int failed_transactions = 0;
    int okay_count = 0;
    int slverr_count = 0;
    int failed_tests = 0;
    

    bit DebugEn = 1;
    parameter int DATA_WIDTH = 32;
    parameter int MAX_TIMEOUT = 1000;
    
    function new(string name= "driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info(get_type_name(), "Driver build phase", UVM_MEDIUM)

        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif)) 
            `uvm_fatal(get_full_name(), {"virtual interface must be set for:", ".intf"});
        
        if(!uvm_config_db#(common_cfg)::get(this, "", "m_cfg", m_cfg))
            `uvm_fatal("DRV_CFG", "Failed to get m_cfg from config DB");
    endfunction

    task run_phase(uvm_phase phase);
        transaction_t req, actual_tx;
        
        wait(vif.ARESETn);
        initialize_interface();
        
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("DRV", $sformatf("=== RECEIVED TRANSACTION ===\n%s", req.convert2string()), UVM_MEDIUM)

            case(req.OP)
                transaction_t::WRITE: begin
                    `uvm_info("DRV", "Processing WRITE transaction", UVM_HIGH)
                    total_write_transactions++;
                    total_write_beats += req.AWLEN + 1;
                    drive_write_transaction(req, actual_tx);
                end
                transaction_t::READ: begin
                    `uvm_info("DRV", "Processing READ transaction", UVM_HIGH)
                    total_read_transactions++;
                    total_read_beats += req.ARLEN + 1;
                    drive_read_transaction(req, actual_tx);
                end
                default: `uvm_error("DRV", $sformatf("Unknown operation: %s", req.OP.name()))
            endcase
            
            if (m_cfg != null) begin
                -> m_cfg.stimulus_sent_e;
            end
            
            seq_item_port.item_done();
            `uvm_info("DRV", "Transaction completed", UVM_HIGH)
        end
    endtask

    task initialize_interface();
        if (!vif.ARESETn) return;
        
        @(posedge vif.ACLK);
        vif.AWVALID <= 1'b0;
        vif.WVALID  <= 1'b0;
        vif.WLAST   <= 1'b0;
        vif.BREADY  <= 1'b0;
        vif.ARVALID <= 1'b0;
        vif.RREADY  <= 1'b0;
        vif.AWADDR  <= '0;
        vif.AWLEN   <= '0;
        vif.AWSIZE  <= '0;
        vif.WDATA   <= '0;
        vif.ARADDR  <= '0;
        vif.ARLEN   <= '0;
        vif.ARSIZE  <= '0;
        @(posedge vif.ACLK);
    endtask

    task automatic drive_write_transaction(input transaction_t tr, ref transaction_t actual_tx);
        logic [1:0] bresp_captured;
        int timeout_counter;
        
        actual_tx = transaction_t::type_id::create("actual_tx");
        actual_tx.OP = tr.OP;
        actual_tx.AWADDR = tr.AWADDR;
        actual_tx.AWLEN = tr.AWLEN;
        actual_tx.AWSIZE = tr.AWSIZE;
        actual_tx.WDATA = new[tr.WDATA.size()];
        
        foreach (tr.WDATA[i]) 
            actual_tx.WDATA[i] = tr.WDATA[i];

        if (tr.awvalid_delay > 0) begin
            repeat(tr.awvalid_delay) @(posedge vif.ACLK);
        end


        `uvm_info("DRV", $sformatf("Starting address phase: AWADDR=0x%h, AWLEN=%0d, AWSIZE=%0d", 
                tr.AWADDR, tr.AWLEN, tr.AWSIZE), UVM_MEDIUM)
        
        if (tr.awvalid_value) 
            begin
                vif.AWADDR  <= tr.AWADDR;
                vif.AWLEN   <= tr.AWLEN;
                vif.AWSIZE  <= tr.AWSIZE;
                vif.AWVALID <= 1'b1;
                
                @(posedge vif.ACLK);
                vif.AWVALID <= 1'b0;
                `uvm_info("DRV", "Address handshake completed", UVM_HIGH)
            end 
        else 
            begin
                @(posedge vif.ACLK);
                vif.AWVALID <= 1'b0;
                `uvm_info("DRV", "Address phase skipped - transaction aborted", UVM_MEDIUM)
                actual_tx.BRESP = 2'b10;
                return;
            end

        // DATA PHASE - Wait for DUT to transition W_IDLE -> W_ADDR -> W_DATA
        `uvm_info("DRV", "Starting data phase", UVM_MEDIUM)

        // Wait one clock for DUT state transition to W_DATA (where WREADY=1)
        @(posedge vif.ACLK);

        foreach (tr.WDATA[i]) begin
            if (tr.wvalid_delay[i] > 0) begin
                repeat(tr.wvalid_delay[i]) @(posedge vif.ACLK);
            end
            
            vif.WDATA  <= tr.WDATA[i];
            vif.WLAST  <= (i == tr.WDATA.size() - 1);
            vif.WVALID <= tr.wvalid_pattern[i];
            
            if (tr.wvalid_pattern[i]) begin
                // Now WREADY should be available since DUT is in W_DATA state
                timeout_counter = 0;
                while (!(vif.WVALID && vif.WREADY)) begin
                    @(posedge vif.ACLK);
                    timeout_counter++;
                    if (timeout_counter >= MAX_TIMEOUT) begin
                        `uvm_info("DRV", $sformatf("TIMEOUT: WREADY not received for beat %0d", i), UVM_MEDIUM)
                        vif.WVALID <= 1'b0;
                        vif.WLAST <= 1'b0;
                        return;
                    end
                end
                
                @(posedge vif.ACLK);  // Complete handshake
                `uvm_info("DRV", $sformatf("Data beat %0d completed: 0x%h", i, tr.WDATA[i]), UVM_HIGH)
            end else begin
                @(posedge vif.ACLK);
            end
            
            vif.WVALID <= 1'b0;
            vif.WLAST <= 1'b0;
        end

        // RESPONSE PHASE - DUT transitions to W_RESP state after last data beat
        `uvm_info("DRV", "Starting response phase", UVM_HIGH)
        
        // DUT asserts BVALID in W_RESP state (may take 1 cycle after WLAST)
        timeout_counter = 0;
        while (!vif.BVALID) begin
            @(posedge vif.ACLK);
            timeout_counter++;
            if (timeout_counter >= MAX_TIMEOUT) begin
                `uvm_info("DRV", "TIMEOUT: BVALID not received", UVM_MEDIUM)
                return;
            end
        end
        
        bresp_captured = vif.BRESP;
        `uvm_info("DRV", $sformatf("BVALID asserted, BRESP: %s", decode_response(bresp_captured)), UVM_MEDIUM)
        
        // Complete response handshake
        if (tr.bready_value) 
            begin
                vif.BREADY <= 1'b1;
                @(posedge vif.ACLK);  // DUT transitions back to W_IDLE
                vif.BREADY <= 1'b0;
            end 
        else 
            begin
                // Delayed response acceptance
                vif.BREADY <= 1'b0;
                repeat($urandom_range(2, 5)) @(posedge vif.ACLK);
                vif.BREADY <= 1'b1;
                @(posedge vif.ACLK);
                vif.BREADY <= 1'b0;
            end

        // Update statistics
        if (is_error_response(bresp_captured)) 
            begin
                slverr_count++;
            end 
        else 
            begin
                okay_count++;
            end

        actual_tx.BRESP = bresp_captured;
        `uvm_info("DRV", $sformatf("Write transaction complete: BRESP=%s", 
                 decode_response(bresp_captured)), UVM_MEDIUM)
    endtask

    task automatic drive_read_transaction(input transaction_t tr, ref transaction_t actual_tx);
        int timeout_counter;
        
        actual_tx = transaction_t::type_id::create("actual_tx");
        actual_tx.OP = tr.OP;
        actual_tx.ARADDR = tr.ARADDR;
        actual_tx.ARLEN = tr.ARLEN;
        actual_tx.ARSIZE = tr.ARSIZE;
        actual_tx.RDATA = new[tr.ARLEN + 1];
        
        if (tr.arvalid_delay > 0) begin
            repeat(tr.arvalid_delay) @(posedge vif.ACLK);
        end
        
        // ADDRESS PHASE - DUT starts in R_IDLE with ARREADY=1
        `uvm_info("DRV", $sformatf("Starting read address phase: ARADDR=0x%h, ARLEN=%0d", 
                 tr.ARADDR, tr.ARLEN), UVM_MEDIUM)
        
        if (tr.arvalid_value) 
            begin
                vif.ARADDR  <= tr.ARADDR;
                vif.ARLEN   <= tr.ARLEN;
                vif.ARSIZE  <= tr.ARSIZE;
                vif.ARVALID <= 1'b1;
                
                // Single clock cycle - handshake completes immediately since ARREADY=1 in IDLE
                @(posedge vif.ACLK);
                vif.ARVALID <= 1'b0;
                `uvm_info("DRV", "Read address handshake completed", UVM_HIGH)
            end 
        else 
            begin
                @(posedge vif.ACLK);
                vif.ARVALID <= 1'b0;
                `uvm_info("DRV", "Read address phase skipped - transaction aborted", UVM_MEDIUM)
                return;
            end
        
        // DATA PHASE - DUT goes through R_ADDR (mem_en=1) then R_DATA (data available)
        for (int i = 0; i <= tr.ARLEN; i++) begin
            // Wait for RVALID (DUT asserts in R_DATA state after memory read)
            timeout_counter = 0;
            while (!vif.RVALID) begin
                @(posedge vif.ACLK);
                timeout_counter++;
                if (timeout_counter >= MAX_TIMEOUT) begin
                    `uvm_info("DRV", $sformatf("TIMEOUT: RVALID not received for beat %0d", i), UVM_MEDIUM)
                    return;
                end
            end
            
            // Handle RREADY based on test configuration
            if (tr.rready_value) 
                begin
                    vif.RREADY <= 1'b1;
                    
                    // Complete handshake - capture data when both RVALID && RREADY
                    while (!(vif.RVALID && vif.RREADY)) begin
                        @(posedge vif.ACLK);
                    end
                    
                    // Data is valid at this clock edge
                    actual_tx.RDATA[i] = vif.RDATA;
                    actual_tx.RRESP = vif.RRESP;
                    
                    // Check RLAST on final beat
                    if (i == tr.ARLEN && !vif.RLAST) begin
                        `uvm_error("DRV", "RLAST not asserted on final beat")
                        failed_tests++;
                    end

                    @(posedge vif.ACLK);  // Complete handshake
                    vif.RREADY <= 1'b0;
                    
                    `uvm_info("DRV", $sformatf("Read beat %0d: RDATA=0x%h, RLAST=%0d", 
                            i, actual_tx.RDATA[i], vif.RLAST), UVM_HIGH)
                    
                end 
            else 
                begin
                    // Delayed RREADY acceptance
                    vif.RREADY <= 1'b0;
                    repeat($urandom_range(2, 5)) @(posedge vif.ACLK);
                    vif.RREADY <= 1'b1;
                    @(posedge vif.ACLK);
                    vif.RREADY <= 1'b0;
                    
                    actual_tx.RDATA[i] = 32'h00000000;
                    actual_tx.RRESP = 2'b00;
                end
        end
        
        `uvm_info("DRV", "Read transaction complete", UVM_MEDIUM)
    endtask

    function string decode_response(logic [1:0] resp);
        case(resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "UNKNOWN";
        endcase
    endfunction
    
    function bit is_error_response(logic [1:0] resp);
        return (resp == 2'b10 || resp == 2'b11);
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("DRV_STATS", "=== DRIVER PERFORMANCE STATISTICS ===", UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Total Write Transactions: %0d", total_write_transactions), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Total Read Transactions:  %0d", total_read_transactions), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Total Write Beats:        %0d", total_write_beats), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Total Read Beats:         %0d", total_read_beats), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Failed Transactions:      %0d", failed_transactions), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("OKAY Responses:           %0d", okay_count), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("SLVERR Responses:         %0d", slverr_count), UVM_LOW)
        `uvm_info("DRV_STATS", $sformatf("Failed Tests:             %0d", failed_tests), UVM_LOW)
        
        if (total_write_transactions > 0) begin
            real avg_write_burst = real'(total_write_beats) / real'(total_write_transactions);
            `uvm_info("DRV_STATS", $sformatf("Average Write Burst Size: %.2f", avg_write_burst), UVM_LOW)
        end
        
        if (total_read_transactions > 0) begin
            real avg_read_burst = real'(total_read_beats) / real'(total_read_transactions);
            `uvm_info("DRV_STATS", $sformatf("Average Read Burst Size:  %.2f", avg_read_burst), UVM_LOW)
        end
        
        if (failed_transactions == 0 && failed_tests == 0) begin
            `uvm_info("DRV_STATS", "*** ALL DRIVER TRANSACTIONS SUCCESSFUL ***", UVM_LOW)
        end else begin
            `uvm_error("DRV_STATS", $sformatf("*** %0d DRIVER TRANSACTIONS FAILED, %0d TESTS FAILED ***", failed_transactions, failed_tests))
        end
        
        `uvm_info("DRV_STATS", "======================================", UVM_LOW)
    endfunction

endclass
`endif
`ifndef DRIVER_SVH
`define DRIVER_SVH
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;
class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)
    virtual intf vif;
    common_cfg m_cfg;
    function new(string name= "driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info(get_type_name(), "Driver constructor - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Driver constructor - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Driver constructor - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Driver constructor - UVM_FULL", UVM_FULL)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual intf)::get(this, "", "intf", vif)) 
            begin
                `uvm_fatal(get_full_name(), {"virtual interface must be set for:", ".intf"});
            end
        else 
            begin
                $display ("[Driver] Corrct accessing of DB!");    
            end
        `uvm_info(get_type_name(), "Driver build phase - UVM_LOW", UVM_LOW)
        `uvm_info(get_type_name(), "Driver build phase - UVM_MEDIUM", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Driver build phase - UVM_HIGH", UVM_HIGH)
        `uvm_info(get_type_name(), "Driver build phase - UVM_FULL", UVM_FULL)
    endfunction

    task drive(transaction req);
        @(negedge vif.clk);
        if(!vif.rst_n) begin
           vif.data_in0  = req.data_in0  ;
           vif.data_in1  = req.data_in1  ;
           vif.data_in2  = req.data_in2  ;
           vif.data_in3  = req.data_in3  ;
           vif.valid_in0 = req.valid_in0 ;
           vif.valid_in1 = req.valid_in1 ;
           vif.valid_in2 = req.valid_in2 ;
           vif.valid_in3 = req.valid_in3 ;
        end
        ->m_cfg.sitmulus_sent_e;
    endtask

    task run_phase(uvm_phase phase);
        forever begin
            transaction req;
            seq_item_port.get_next_item(req);
                drive(req); 
            seq_item_port.item_done();
        end
    endtask
endclass
`endif
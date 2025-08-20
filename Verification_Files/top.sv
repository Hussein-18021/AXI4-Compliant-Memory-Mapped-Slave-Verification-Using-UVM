`include "intf.sv"
`include "uvm_macros.svh"
import package_::*;
import uvm_pkg::*;
module top;
    intf vif();

    router DUT (
        .clk        (vif.clk),
        .rst_n      (vif.rst_n),
        .data_in0   (vif.data_in0),
        .data_in1   (vif.data_in1),
        .data_in2   (vif.data_in2),
        .data_in3   (vif.data_in3),
        .valid_in0  (vif.valid_in0),
        .valid_in1  (vif.valid_in1),
        .valid_in2  (vif.valid_in2),
        .valid_in3  (vif.valid_in3),
        .data_out0  (vif.data_out0),
        .data_out1  (vif.data_out1),
        .valid_out0 (vif.valid_out0),
        .valid_out1 (vif.valid_out1)
    );
    
    initial begin 
        vif.clk=0;
        forever begin
            #2ns vif.clk = ~ vif.clk;
        end
    end

    initial begin
        uvm_config_db #(uvm_active_passive_enum)::set(null, "uvm_test_top.env.agent_", "is_active", UVM_ACTIVE);
        uvm_config_db #(virtual intf)::set(null, "uvm_test_top.env.agent_.*", "intf", vif);
        run_test("test");
    end

endmodule
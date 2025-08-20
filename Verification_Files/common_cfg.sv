`ifndef common_cfg_SVH
`define common_cfg_SVH
`include "uvm_macros.svh"
import uvm_pkg::*;

class common_cfg extends uvm_object;
    `uvm_object_utils(common_cfg)
    event stimulus_sent_e;
    function new(string name = "common_cfg");
        super.new(name);
    endfunction
endclass
`endif
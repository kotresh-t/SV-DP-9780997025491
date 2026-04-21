import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

// Simple sequencer for traffic transactions
class traffic_sequencer extends uvm_sequencer#(traffic_trans);
  `uvm_component_utils(traffic_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

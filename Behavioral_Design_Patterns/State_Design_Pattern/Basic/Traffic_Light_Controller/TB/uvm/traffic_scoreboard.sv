import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

class traffic_scoreboard extends uvm_component;
  `uvm_component_utils(traffic_scoreboard)

  uvm_analysis_imp#(traffic_trans, traffic_scoreboard) analysis_export;
  int unsigned sample_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    sample_count = 0;
  endfunction

  function void write(traffic_trans t);
    sample_count++;
    `uvm_info("SCORE", $sformatf("sample %0d: %s", sample_count, t.convert2string()), UVM_LOW)
  endfunction

  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info("SCORE", $sformatf("Total samples observed: %0d", sample_count), UVM_LOW)
  endfunction

endclass
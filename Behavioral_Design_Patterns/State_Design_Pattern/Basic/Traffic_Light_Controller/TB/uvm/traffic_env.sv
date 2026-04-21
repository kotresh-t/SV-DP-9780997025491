import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

class traffic_env extends uvm_env;
  `uvm_component_utils(traffic_env)

 
  traffic_sequencer sequencer;
  traffic_driver    driver;
  traffic_monitor   monitor;
  traffic_scoreboard scoreboard;
  traffic_state_checker checker_m;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = traffic_sequencer::type_id::create("sequencer", this);
    driver    = traffic_driver::type_id::create("driver", this);
    monitor = traffic_monitor::type_id::create("monitor", this);
    scoreboard = traffic_scoreboard::type_id::create("scoreboard", this);
    checker_m = traffic_state_checker::type_id::create("checker_m", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.analysis_port.connect(scoreboard.analysis_export);
    monitor.analysis_port.connect(checker_m.analysis_export);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
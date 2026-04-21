import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

class traffic_test extends uvm_test;
  `uvm_component_utils(traffic_test)

  traffic_env env;
  traffic_basic_seq seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = traffic_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);
    `uvm_info("TRAFFIC_TEST", "UVM traffic test running — starting basic sequence", UVM_LOW)
    seq = traffic_basic_seq::type_id::create("seq");
    seq.start(env.sequencer);
    #240ns;
    phase.drop_objection(this);
  endtask


endclass
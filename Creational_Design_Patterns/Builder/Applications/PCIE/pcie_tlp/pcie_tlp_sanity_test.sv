// pcie_tlp_sanity_test.sv
`include "uvm_macros.svh"
import uvm_pkg::*;
import uvm_tlm_pkg::*;

// Virtual sequencer (simple version)
class pcie_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(pcie_virtual_sequencer)
  pcie_tlp_sequencer tlp_sqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

// Sanity sequence
class pcie_tlp_sanity_seq extends uvm_sequence #(pcie_tlp_item);
  `uvm_object_utils(pcie_tlp_sanity_seq)
  task body();
    pcie_tlp_item tlp = pcie_tlp_item::type_id::create("tlp");
    start_item(tlp);
    assert(tlp.randomize() with {
      fmt_type == 8'h0;          // MemWr
      address == 64'h1000_0000;
      data.size() == 1;
      data[0] == 32'hCAFE_BABE;
      requester_id == 16'h0010;
      completer_id == 16'h0100;
    });
    finish_item(tlp);
  endtask
endclass

// Environment
class pcie_tlp_env extends uvm_env;
  `uvm_component_utils(pcie_tlp_env)
  pcie_tlp_agent agent;
  pcie_virtual_sequencer vseqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = pcie_tlp_agent::type_id::create("agent", this);
    vseqr = pcie_virtual_sequencer::type_id::create("vseqr", this);
    vseqr.tlp_sqr = agent.sequencer;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect agent TX → DUT input
    agent.tx_ap.connect(rc_to_dut.analysis_export);
    // Connect DUT output → agent RX
    dut_to_ep.connect(agent.rx_export);
  endfunction
endclass

// Test
class pcie_tlp_sanity_test extends uvm_test;
  `uvm_component_utils(pcie_tlp_sanity_test)
  pcie_tlp_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pcie_tlp_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_tlp_sanity_seq seq = pcie_tlp_sanity_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.vseqr.tlp_sqr);
    phase.drop_objection(this);
  endtask
endclass
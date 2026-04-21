// pcie_dllp_sanity_test.sv
class pcie_dllp_sanity_seq extends uvm_sequence #(pcie_dllp_item);
`uvm_object_utils(pcie_dllp_sanity_seq)
task body();
  pcie_dllp_item dllp = pcie_dllp_item::type_id::create("dllp");
  start_item(dllp);
  assert(dllp.randomize() with { type == DLLP_ACK; ack_nak_seq_num == 12'hABC; });
  finish_item(dllp);
endtask
endclass

class pcie_link_env_wrapper extends uvm_env;
pcie_link_env env;
pcie_virtual_sequencer vseqr;

function void build_phase(uvm_phase phase);
  env = pcie_link_env::type_id::create("env", this);
  vseqr = pcie_virtual_sequencer::type_id::create("vseqr", this);
  vseqr.link_sqr = env.link_agent.sequencer;
endfunction

function void connect_phase(uvm_phase phase);
  env.link_agent.tx_ap.connect(rc_to_dut.analysis_export);
  dut_to_ep.connect(env.link_agent.rx_export);
endfunction
endclass

class pcie_dllp_sanity_test extends uvm_test;
pcie_link_env_wrapper wrapper;
function void build_phase(uvm_phase phase);
  wrapper = pcie_link_env_wrapper::type_id::create("wrapper", this);
endfunction
task run_phase(uvm_phase phase);
  pcie_dllp_sanity_seq seq = pcie_dllp_sanity_seq::type_id::create("seq");
  phase.raise_objection(this);
  seq.start(wrapper.vseqr.link_sqr);
  phase.drop_objection(this);
endtask
endclass
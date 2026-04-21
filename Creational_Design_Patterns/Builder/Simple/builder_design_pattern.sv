/* This example demonstrates how chaining can be used to create a construction of complex objects in a step-by-step manner. 
 * We have a class 'axi_txn' that represents an AXI transaction with various fields. 
 * We have a builder class 'axi_txn_builder' that provides methods to set the fields of the transaction and a method to build the final transaction object. 
 * The builder allows for method chaining, making it easy to construct complex transactions in a readable way.
 * In the testbench, we create an instance of the builder, set various fields, and then build the transaction object which is then used in a sequence.
 * Example usage:
    txn = b.with_addr(32'hDEAD_BEEF)
           .with_data(32'hCAFE_BABE)
           .with_crc()
           .build();
 */
 
// axi_txn.sv
`ifndef AXI_TXN_SV
`define AXI_TXN_SV
// top.sv
module top;
import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_txn extends uvm_sequence_item;
  `uvm_object_utils(axi_txn)

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        include_crc;
  bit [31:0]      crc_value; // not randomized—computed

  function new(string name = "axi_txn");
    super.new(name);
  endfunction

  // Optional: add constraints if needed
  // constraint c_valid { addr inside {[32'h1000:32'hFFFF]}; }

endclass

class axi_txn_builder;
  local axi_txn txn;

  function new();
    txn = axi_txn::type_id::create("txn");
  endfunction

  function axi_txn_builder with_addr(bit [31:0] a);
    txn.addr = a;
    return this;
  endfunction

  function axi_txn_builder with_data(bit [31:0] d);
    txn.data = d;
    return this;
  endfunction

  function axi_txn_builder with_crc();
    txn.include_crc = 1;
    return this;
  endfunction

  function axi_txn_builder randomize_txn();
    assert(txn.randomize())
      else `uvm_fatal("RAND", "Randomization failed")
    return this;
  endfunction

  function axi_txn build();
    validate();
    if (txn.include_crc)
      txn.crc_value = compute_crc(txn);
    return txn;
  endfunction

  local function bit [31:0] compute_crc(axi_txn t);
    return t.addr ^ t.data;
  endfunction

  local function void validate();
    if (^txn.addr === 1'bX || ^txn.data === 1'bX)
      `uvm_fatal("BUILDER", "Address or data not initialized")
  endfunction
endclass
class my_seq extends uvm_sequence #(axi_txn);
  `uvm_object_utils(my_seq)

  function new(string name = "my_seq");
    super.new(name);
  endfunction

  task body();
    axi_txn txn;
    axi_txn_builder b = new();

    txn = b.with_addr(32'hDEAD_BEEF)
           .with_data(32'hCAFE_BABE)
           .with_crc()
           .build();

    start_item(txn);
    finish_item(txn);
  endtask
endclass
class my_driver extends uvm_driver #(axi_txn);
  `uvm_component_utils(my_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_txn req;
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("DRV",
        $sformatf("Driving txn addr=0x%0h", req.addr),
        UVM_MEDIUM)
      seq_item_port.item_done();
    end
  endtask
endclass

class axi_sequencer extends uvm_sequencer #(axi_txn);
  `uvm_component_utils(axi_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class my_agent extends uvm_agent;
  `uvm_component_utils(my_agent)

  axi_sequencer  sqr;
  my_driver                drv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = axi_sequencer::type_id::create("sqr", this);
    drv = my_driver::type_id::create("drv", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = my_agent::type_id::create("agent", this);
  endfunction

  task run_phase(uvm_phase phase);
    my_seq seq;
    phase.raise_objection(this);
    seq = my_seq::type_id::create("seq");
    seq.start(agent.sqr);
    phase.drop_objection(this);
  endtask
endclass
class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_config_db#(int)::set(
      this,
      "env.agent.drv",
      "recording_detail",
      UVM_FULL
    );
  endfunction
endclass

  initial begin
    run_test("my_test");
  end
endmodule
`endif 
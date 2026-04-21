import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

// Driver is primarily a place-holder for reset/active stimulus and future fault-injection.
class traffic_driver extends uvm_driver#(traffic_trans);
  `uvm_component_utils(traffic_driver)

  virtual traffic_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual traffic_if)::get(this, "", "vif", vif)) begin
      `uvm_info("NO_VIF", "Virtual interface not set for traffic_driver — driver will be passive.", UVM_LOW)
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    traffic_trans tr;

    // If driver has the interface, apply a canonical reset pulse early in run_phase
    if (vif != null) begin
      vif.rst_a = 1'b1;
      repeat(3) @(posedge vif.clk);
      vif.rst_a = 1'b0;
    end

    // Accept sequence items if any (no-op for now). Useful hook for future stimulus.
    forever begin
      seq_item_port.get_next_item(tr);
      // future: decode tr and inject stimuli/faults
      seq_item_port.item_done();
    end
  endtask

endclass
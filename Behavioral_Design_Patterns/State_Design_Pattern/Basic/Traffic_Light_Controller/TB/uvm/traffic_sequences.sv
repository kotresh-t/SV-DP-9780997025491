import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

// Basic sequence that sends a few traffic_trans items to the driver/sequencer.
class traffic_basic_seq extends uvm_sequence#(traffic_trans);
  `uvm_object_utils(traffic_basic_seq)

  function new(string name = "traffic_basic_seq");
    super.new(name);
  endfunction

  virtual task body();
    traffic_trans tr;

    // send a small burst of items (driver is currently passive but this
    // demonstrates the Sequence/Command pattern and provides a hook
    // for future stimulus/fault-injection).
    repeat (6) begin
      tr = traffic_trans::type_id::create("tr");
      // items can carry optional expected fields for future use
      start_item(tr);
      finish_item(tr);
      // pacing between items (time-based to remain simulator-agnostic)
      #20ns;
    end
  endtask
endclass

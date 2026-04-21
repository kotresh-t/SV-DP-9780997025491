// tb.sv
interface dummy_if; endinterface

module tb;

`include "uvm_macros.svh"
import uvm_pkg::*; 
`include "packet.sv"
`include "my_sequencer.sv"
`include "protocol_impl.sv"
`include "my_sequence.sv"
`include "my_driver.sv"
`include "my_agent.sv"
`include "my_env.sv"
`include "my_test.sv"

  dummy_if vif();

  initial begin
    run_test("my_test");
  end
endmodule
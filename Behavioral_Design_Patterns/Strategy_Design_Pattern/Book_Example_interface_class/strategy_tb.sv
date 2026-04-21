
`include "axi_if.sv"

module tb;
  `include "uvm_macros.svh"
  import uvm_pkg::*; 

  `include "strategy_interface.sv"
  `include "write_transaction.sv"
  `include "weighted_address_strategy.sv"
  `include "axi_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_agent.sv"
  `include "flexible_write_sequence.sv"
  `include "random_address_strategy.sv"
  `include "sequential_address_strategy.sv"
  `include "strategy_verification_env.sv"
  `include "strategy_test.sv"

  bit clk;
  always #5 clk = ~clk;

  axi_if vif(clk);

  // DUT stub
  assign vif.awready = 1;

  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
    run_test("axi_test");
    #100; 
  end
endmodule
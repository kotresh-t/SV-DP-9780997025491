// tb.sv


module tb;

`include "uvm_macros.svh"
import uvm_pkg::*;
import uvm_tlm_pkg::*;

// tb.sv

  pcie_dllp_trx_if rc_to_dut();
  pcie_dllp_trx_if dut_to_ep();

  // Instantiate DUT
  pcie_dllp_dut dut (.*);
  initial begin
    uvm_config_db#(virtual pcie_dllp_trx_if)::set(null, "uvm_test_top.wrapper.env.link_agent.driver", "vif", rc_to_dut);
    uvm_config_db#(virtual pcie_dllp_trx_if)::set(null, "uvm_test_top.wrapper.env.link_agent.monitor", "vif", dut_to_ep);
  end
  initial begin
    run_test("pcie_dllp_sanity_test");
  end
endmodule
// tb.sv

// Instantiate TLM analysis interfaces
//uvm_tlm_analysis_if #(pcie_tlp_item) rc_to_dut();
//uvm_tlm_analysis_if #(pcie_tlp_item) dut_to_ep();

module tb;

`include "uvm_macros.svh"
import uvm_pkg::*;
import uvm_tlm_pkg::*;
  
// Instantiate TLM analysis interfaces
uvm_tlm_analysis_if #(pcie_tlp_item) rc_to_dut();
uvm_tlm_analysis_if #(pcie_tlp_item) dut_to_ep();

  initial begin
    run_test("pcie_tlp_sanity_test");
  end

  // DUT instance
  pcie_tlp_dut dut (
    .tx_in (rc_to_dut),
    .rx_out(dut_to_ep)
  );
endmodule
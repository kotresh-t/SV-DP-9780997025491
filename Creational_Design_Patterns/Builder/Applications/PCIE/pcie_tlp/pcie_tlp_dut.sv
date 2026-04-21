// pcie_tlp_dut.sv
module pcie_tlp_dut (
    input  uvm_tlm_analysis_if #(pcie_tlp_item) tx_in,
    output uvm_tlm_analysis_if #(pcie_tlp_item) rx_out
  );
  
    // Simple passthrough with delay
    always @(posedge tx_in.put_event) begin
      pcie_tlp_item tlp = tx_in.get_transaction();
      #10; // Simulate latency
      rx_out.put(tlp);
    end
  
endmodule
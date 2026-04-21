// pcie_dllp_dut.sv
module pcie_dllp_dut (
    pcie_dllp_trx_if tx_in,
    pcie_dllp_trx_if rx_out
  );
  
    always @(posedge tx_in.put_event) begin
      pcie_dllp_item dllp = new tx_in.trx; // copy
      #5;
      rx_out.put(dllp);
    end
  
  endmodule
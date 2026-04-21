
`ifndef AXI_AHB_ADAPTER_SV
`define AXI_AHB_ADAPTER_SV
 
class transaction_adapter;

  // Convert AHB transaction to AXI transaction
  function void convert_ahb_to_axi(ahb_transaction ahb_trans, output axi_transaction axi_trans);
    axi_trans = new();
    
    // Example conversion logic
    axi_trans.awaddr = ahb_trans.haddr;
    axi_trans.wdata = ahb_trans.hwdata;
    axi_trans.awlen = 0; // Single beat for simplicity
    axi_trans.awsize = ahb_trans.hsize;
    axi_trans.awvalid = 1;
    axi_trans.wvalid = 1;
    axi_trans.wlast = 1; // Completing the transaction
  endfunction

  // Convert AXI transaction to AHB transaction
  function void convert_axi_to_ahb(axi_transaction axi_trans, output ahb_transaction ahb_trans);
    ahb_trans = new();
    
    // Example conversion logic
    ahb_trans.haddr = axi_trans.awaddr;
    ahb_trans.hwdata = axi_trans.wdata;
    ahb_trans.hsize = axi_trans.awsize;
    ahb_trans.hwrite = 1; // Assuming write operation for simplicity
    ahb_trans.hready = 1;
  endfunction

endclass

`endif // AXI_AHB_ADAPTER_SV

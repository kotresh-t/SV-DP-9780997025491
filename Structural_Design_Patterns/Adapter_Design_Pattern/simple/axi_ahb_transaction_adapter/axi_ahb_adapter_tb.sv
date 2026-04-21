/* This example demonstrates class based adapter or conversion in SystemVerilog. 
 * We have two interfaces, AXI and AHB, which are commonly used in hardware design. The adapter class 'transaction_adapter' provides methods to convert transactions between these two interfaces.
 * The 'convert_ahb_to_axi' method takes an AHB transaction as input and produces a corresponding AXI transaction, while the 'convert_axi_to_ahb' method does the reverse.
 * This allows components designed for one interface to interact with components designed for the other interface without modification, promoting code reuse and flexibility in system design.
 */
 
`ifndef AXI_AHB_TB_SV
`define AXI_AHB_TB_SV

module testbench;
  ahb_transaction ahb_trans;
  axi_transaction axi_trans;
  transaction_adapter adapter;

  initial begin
    ahb_trans = new();
    axi_trans = new();
    adapter = new();

    // Randomize AHB transaction
    assert(ahb_trans.randomize());
    $display("Original AHB Transaction: Addr = %h, Data = %h, Size = %d", ahb_trans.haddr, ahb_trans.hwdata, ahb_trans.hsize);

    // Convert AHB to AXI
    adapter.convert_ahb_to_axi(ahb_trans, axi_trans);
    $display("Converted AXI Transaction: Addr = %h, Data = %h, Len = %d, Size = %d", axi_trans.awaddr, axi_trans.wdata, axi_trans.awlen, axi_trans.awsize);

    // Convert back to AHB for demonstration
    ahb_transaction new_ahb_trans;
    adapter.convert_axi_to_ahb(axi_trans, new_ahb_trans);
    $display("Converted Back AHB Transaction: Addr = %h, Data = %h", new_ahb_trans.haddr, new_ahb_trans.hwdata);

    $finish;
  end

  // Clock generator
  always #10 ahb_trans.hclk = ~ahb_trans.hclk;
endmodule


`endif //AXI_AHB_TB_SV

/* 
 * This example demonstrates composition in SystemVerilog.
 * We have a base class 'axi_txn' that represents an AXI transaction with address and data fields.
 * We also have a separate class 'txn_metadata' that holds optional metadata for the transaction, such as delay cycles and CRC information.
 * The 'axi_txn' class has a member of type 'txn_metadata', demonstrating a "has-a" relationship (composition) between the two classes.
 * In the testbench, we create an instance of 'axi_txn', set its address and data, and then populate the metadata with delay and CRC information before displaying the transaction details.
 */

module tb(); 

// Optional metadata as a separate object
class txn_metadata;
  int delay_cycles = 0;
  bit has_crc = 0;
  bit [31:0] crc = 0;
endclass

// Base transaction holds optional metadata
class axi_txn;
  bit [31:0] addr;
  bit [31:0] data;
  txn_metadata meta; // Composition: "has-a" relationship

  function new();
    meta = new(); // Default metadata
  endfunction

  function void display();
    $display("AXI Txn: addr=0x%0h, data=0x%0h", addr, data);
    if (meta.delay_cycles > 0)
      $display("  → Delay: %0d cycles", meta.delay_cycles);
    if (meta.has_crc)
      $display("  → CRC: 0x%0h", meta.crc);
  endfunction
endclass

axi_txn txn = new;

initial begin 
    txn.addr = 32'h3000;
    txn.data = 32'hDEAD;

    // Add delay dynamically
    txn.meta.delay_cycles = 3;

    // Or enable CRC
    txn.meta.has_crc = 1;
    txn.meta.crc = txn.addr ^ txn.data;

    txn.display();
end 

endmodule // tb 

/* Results: 
    # AXI Txn: addr=0x3000, data=0xdead
#   â Delay: 3 cycles
#   â CRC: 0xeead
*/ 

`ifndef AXI_TRANSACTION_CL
`define AXI_TRANSACTION_CL

class AXITransaction;
  rand bit [31:0] address;
  rand bit [31:0] data;
  rand bit [2:0] burst_type;

  // Constraint to align addresses for bursts
  constraint aligned_address {
    address[1:0] == 2'b00;  // Ensuring address is word-aligned
  }

  // Constraint to limit burst types to defined types
  constraint valid_burst_types {
    burst_type inside {1, 2, 4}; // Assuming 1, 2, 4 are valid burst types
  }
endclass

class AHBTransaction;
  rand bit [31:0] address;
  rand bit [31:0] data;
  rand bit read_write; // 0 for read, 1 for write

  // Constraint for read/write balance
  constraint read_write_balance {
    read_write dist {1'b0 := 50, 1'b1 := 50}; // 50% reads, 50% writes
  }
endclass

`endif // AXI_TRANSACTION_CL
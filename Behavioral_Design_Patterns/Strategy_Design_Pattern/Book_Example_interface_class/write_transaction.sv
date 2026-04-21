class write_transaction extends uvm_sequence_item;
  rand logic [31:0] addr;
  rand logic [31:0] data;
  `uvm_object_utils_begin(write_transaction)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "write_transaction");
    super.new(name);
  endfunction

endclass
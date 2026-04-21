virtual class address_strategy extends uvm_sequence_item;
`uvm_object_utils(address_strategy)
  function new(string name = "address_strategy");
     super.new(name);
  endfunction
  // Pure virtual - must be implemented by subclasses
  pure virtual function logic [31:0] next_address();
  pure virtual function void reset();
endclass

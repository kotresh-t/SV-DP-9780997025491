// packet.sv
class packet extends uvm_sequence_item;
rand bit [63:0] data;
rand int        len;

`uvm_object_utils_begin(packet)
  `uvm_field_int(data, UVM_ALL_ON)
  `uvm_field_int(len,  UVM_ALL_ON)
`uvm_object_utils_end

    function new(string name = "packet");
       super.new(name);
    endfunction
    
endclass
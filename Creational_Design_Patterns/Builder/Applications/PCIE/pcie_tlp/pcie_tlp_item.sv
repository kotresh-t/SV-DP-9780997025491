class pcie_tlp_item extends uvm_sequence_item;
  rand bit [7:0]  fmt_type;
  rand bit [9:0]  requester_id;
  rand bit [9:0]  completer_id;
  rand bit [63:0] address;
  rand bit [31:0] data[];
  rand bit        has_ecrc;
  // ... other fields

  `uvm_object_utils_begin(pcie_tlp_item)
    `uvm_field_int(fmt_type, UVM_HEX)
    `uvm_field_int(requester_id, UVM_HEX)
    `uvm_field_int(address, UVM_HEX)
    `uvm_field_array_int(data, UVM_HEX)
    `uvm_field_int(has_ecrc, UVM_ALL)
  `uvm_object_utils_end

  function string convert2string();
    return $sformatf("TLP: FmtType=0x%02x, Addr=0x%0h, Len=%0d",
                     fmt_type, address, data.size());
  endfunction
endclass
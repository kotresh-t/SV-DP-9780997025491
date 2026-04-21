package axi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Base txn [file:2]
  class axi_txn extends uvm_sequence_item;
    rand bit        is_write;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  id;      // AXI4
    rand bit [7:0]  len;     // AXI4 burst length
    rand bit [2:0]  size;
    bit [1:0]       resp;
    bit             error_inj;
    
    `uvm_object_utils_begin(axi_txn)
      `uvm_field_int(is_write, UVM_ALL_ON)
      `uvm_field_int(addr,    UVM_ALL_ON)
      `uvm_field_int(data,    UVM_ALL_ON)
      `uvm_field_int(id,      UVM_ALL_ON)
      `uvm_field_int(len,     UVM_ALL_ON)
      `uvm_field_int(size,    UVM_ALL_ON)
      `uvm_field_int(resp,    UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name="axi_txn");
      super.new(name);
    endfunction
  endclass

  // Builder for fluent txn creation (**Builder**) [file:2]
  class axi_txn_builder;
    axi_txn txn;
    
    function new();
      txn = axi_txn::type_id::create("txn");
    endfunction
    
    function axi_txn_builder with_write();
      txn.is_write = 1;
      return this;
    endfunction
    
    function axi_txn_builder with_read();
      txn.is_write = 0;
      return this;
    endfunction
    
    function axi_txn_builder with_addr(bit[31:0] a);
      txn.addr = a;
      return this;
    endfunction
    
    function axi_txn_builder with_data(bit[31:0] d);
      txn.data = d;
      return this;
    endfunction
    
    function axi_txn_builder with_burst(bit[7:0] l=1, bit[2:0] s=0);
      txn.len  = l;
      txn.size = s;
      return this;
    endfunction
    
    function axi_txn with_error();
      txn.error_inj = 1;
      return build();
    endfunction
    
    function axi_txn build();
      // Encapsulate validation
      if (txn.len == 0) txn.len = 1;
      return txn;
    endfunction
  endclass
endpackage

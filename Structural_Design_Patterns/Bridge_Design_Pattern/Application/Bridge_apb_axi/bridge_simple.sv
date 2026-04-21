// ===== UVM Imports =====
`include "uvm_macros.svh"
import uvm_pkg::*;

// ===== Interfaces =====
interface axi4_if(input bit clk, input bit rst_n);
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;
endinterface

interface apb_if(input bit clk, input bit rst_n);
  logic [31:0] paddr;
  logic        pvalid;
  logic        pready;
endinterface

// ===== Transaction =====
class generic_txn extends uvm_sequence_item;
  rand bit[31:0] addr;
  
  `uvm_object_utils_begin(generic_txn)
    `uvm_field_int(addr, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "generic_txn");
    super.new(name);
  endfunction
endclass

// ===== Test Base =====
class test_base extends uvm_test;
  `uvm_component_utils(test_base)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    string protocol;
    phase.raise_objection(this);
    
    if (!uvm_config_db #(string)::get(this, "", "protocol", protocol))
      protocol = "AXI4";
    
    `uvm_info("test", $sformatf("Using protocol: %s", protocol), UVM_LOW)
    
    #100ns;
    phase.drop_objection(this);
  endtask
endclass

// ===== AXI4 Test =====
class axi4_test extends test_base;
  `uvm_component_utils(axi4_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(string)::set(this, "", "protocol", "AXI4");
  endfunction
endclass

// ===== APB Test =====
class apb_test extends test_base;
  `uvm_component_utils(apb_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(string)::set(this, "", "protocol", "APB");
  endfunction
endclass

// ===== Testbench =====
module tb_bridge_simple;
  reg clk;
  reg rst_n;
  
  axi4_if axi_vif(clk, rst_n);
  apb_if  apb_vif(clk, rst_n);
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
  end
  
  initial begin
    run_test();
  end
  
  initial begin
    #500us $finish;
  end
endmodule

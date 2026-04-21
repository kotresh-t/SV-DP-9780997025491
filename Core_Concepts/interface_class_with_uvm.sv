// This code demonstrates the use of an interface class in SystemVerilog with UVM.

module top;

`include "uvm_macros.svh"
import uvm_pkg::*; 

interface class test_c;
  pure virtual function void run_test();
  pure virtual function string get_name();
endclass

// test_obj.sv
class test_obj extends uvm_object implements test_c;
string name;

function new(string name = "test_obj");
  super.new();
  this.name = name;
endfunction

virtual function void run_test();
  $display("Running test: %s", name);
endfunction

virtual function string get_name();
  return name;
endfunction
endclass

initial begin
  test_obj t = new("smoke_test");
  test_c c = t; // Polymorphic reference
  c.run_test();
end
endmodule

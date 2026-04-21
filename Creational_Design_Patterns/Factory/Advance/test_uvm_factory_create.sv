`include "uvm_macros.svh"
module tb(); 

import uvm_pkg::*; 

class test extends uvm_object; 
	rand int abc; 
	
	function new(string name="test"); 
		super.new(name); 
	endfunction // new 

	`uvm_object_utils_begin(test)
	`uvm_object_utils_end

endclass 

class u_test extends uvm_test; 
	test test_i; 
	
	`uvm_component_utils(u_test)

	function new(string name="u_test",uvm_component parent=null); 
		super.new(name,parent); 
	endfunction // new 

	task run_phase(uvm_phase phase); 
		test_i = test::type_id::create("t"); 
		$display("Hello Test = %p",test_i); 
	endtask // run_phase 

endclass // u_test

initial 
begin 
	test obj; 
	obj = test::type_id::create("obj_1"); 
	obj.randomize(); 
	$display("obj = %p",obj); 
	run_test("u_test");

end 
endmodule 

`ifndef robot_template_cl_sv
`define robot_template_cl_sv

class robot_template_cl_sv; 
	
	function new(); 
	    $display("Created robot base class"); 
	endfunction // new. 

	function start(); 
	   $display("Starting...");
	endfunction //start 

	function getparts(); 
	   $display("Getparts...");
	endfunction // getparts

	function assemble(); 
	   $display("Assembling...");
	endfunction // assemble

	function test(); 
	   $display("Testing...");
	endfunction // test

	function stop(); 
	   $display("Stopping...");
	endfunction // stop 

	function void go(); 
	   start(); 
	   getparts(); 
	   assemble(); 
	   test(); 
	   stop(); 
	endfunction // go

endclass // robot_template_cl_sv

`endif // robot_template_cl_sv 

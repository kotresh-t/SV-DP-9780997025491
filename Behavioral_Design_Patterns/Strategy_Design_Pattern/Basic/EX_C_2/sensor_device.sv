`ifndef sensor_device_sv
`define sensor_device_sv

class sensor_device; 

	/* Create instance of operation mode */ 
	local operation_mode mode; 

	function void setmode(operation_mode op_mode); 
			this.mode = op_mode; 
	endfunction // setmode 
	
	/* Execute the Set Operation Mode */
 	function void execute_operation_mode(); 
 		this.mode.operate(); 
	endfunction // execute_operation_mode

endclass : sensor_device

`endif // sensor_device_sv

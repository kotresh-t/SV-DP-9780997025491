`ifndef operation_mode_sv
`define operation_mode_sv

/* Define Strategy Class */ 
virtual class operation_mode; 

	pure virtual function void operate(); 

endclass : operation_mode

/* Define strategy Functions for all Devices */ 
class normal_mode extends operation_mode; 
	
	virtual function void operate(); 

		$display("Operating Mode in normal Mode"); 
	
	endfunction // operate

endclass : normal_mode

class power_saving_mode extends operation_mode; 
	
	virtual function void operate(); 

		$display("Operation Mode in power saving mode"); 
	
	endfunction // operate

endclass : power_saving_mode

class high_performance_mode extends operation_mode; 

	virtual function void operate(); 
	
		$display("Operation mode is set to high performance mode"); 
	
	endfunction // operate

endclass : high_performance_mode


`endif // operation_mode_sv

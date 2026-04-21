`ifndef TB_SV
`define TB_SV

module tb(); 

`include "operation_mode.sv" 
`include "sensor_device.sv" 

	sensor_device device; 
  normal_mode   nm_mode; 
	power_saving_mode pw_mode; 
	high_performance_mode hp_mode; 

	initial
	begin 
			nm_mode = new();
			pw_mode = new();
		  hp_mode = new(); 

		  // Create sensor device. 
			device = new(); 

			device.setmode(nm_mode); 
			device.execute_operation_mode(); 

			device.setmode(pw_mode); 
			device.execute_operation_mode(); 
			
			device.setmode(hp_mode); 
			device.execute_operation_mode(); 
		end 

endmodule // tb

`endif // TB_SV 

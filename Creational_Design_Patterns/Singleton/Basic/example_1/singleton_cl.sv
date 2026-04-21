class SingleTon; 
		local static SingleTon instance_p = null; 
		
		// Constructor //Try this example without local keyword and with local keyword. 
		local function new(); 
			$display("New SingleTon Class Created"); 
		endfunction // new 

		// Example method
    		function void display();
        		$display("Singleton instance called");
    		endfunction
		
		// Get SingleTon Instance once for simulation. 
		static function SingleTon GetInstance(); 
			if (instance_p == null) begin 
				instance_p = new(); 
			end 
			else begin 
				$error("SingleTon Instance already Available"); 
			end 
			
			return instance_p; 
		endfunction // GetInstance 
endclass // SingleTon
module Singleton_Test(); 

	

	initial 
	begin 
		SingleTon ST_Cl,ST_C2; 
		ST_Cl=SingleTon::GetInstance(); 
		ST_Cl.display(); 
		ST_C2=ST_Cl;
		ST_C2.GetInstance();
		//ST_C2=new();  // This will error out when local keyword is used with new() function. 
		//ST_C2.display(); 
		
	end 

	initial
	begin 
		#600 $finish; 
	end 
endmodule 

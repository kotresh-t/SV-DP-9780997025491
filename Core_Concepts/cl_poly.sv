module tb(); 
	class abc; 
		int i; 
		virtual function disp_a(); 
			$display("%m i = %d",i); 
		endfunction 
	endclass // abc

	class abc_in extends abc; 
		int vec; 
		int i = 200; 	
		function disp_a();
			$display("%m i = %d",i,vec); 
		endfunction 
	endclass // abc_in 	

	abc abc_i; 
	abc_in abc_in_i; 

	initial 
	begin 
		abc_in_i =new(); 
		abc_in_i.i = 20; 
		abc_in_i.vec = 30; 
		abc_i = abc_in_i; 

		abc_i.disp_a(); 
		abc_in_i.disp_a();
	end
endmodule 

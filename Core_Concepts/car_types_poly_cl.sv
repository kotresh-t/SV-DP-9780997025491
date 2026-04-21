class car; 

	typedef enum {AUTOMATIC,MANUAL} transmission_type; 

	int m_num_doors; 
	int m_is_locked[];
       	
	transmission_type m_trans;

	virtual task drive_forward(); 
		$display("Car with transmission: %s is driving forward",m_trans.name()); 
	endtask // drive_forward

	task unlock_door(input int door); 
		m_is_locked[door] = 0; 
	endtask 

	task lock_door(input int door); 
		m_is_locked[door] = 1; 
	endtask 

	task open_door(input int door); 

		if (m_is_locked[door] == 1)
			$display("Must unlock door [%0d] first",door);
		else
			$display("Door [%0d] is now open ", door); 

	endtask // open_door

	function new(input int num_doors = 2, input transmission_type trans=AUTOMATIC); 
	
		m_trans     = trans; 
		m_num_doors = num_doors; 
		m_is_locked = new[num_doors]; 
		
		foreach(m_is_locked[i]) 
			m_is_locked[i] = 1; 
		$display("%m Class is initialized with num_doors = %d trans = %s",num_doors,trans); 

	
	endfunction // new

endclass // car

class hyundai extends car; 

	local bit m_is_convertible; 

	function new(input int num_doors=2,input transmission_type trans=MANUAL); 
		super.new(num_doors,trans);

		$display("%m Class is initialized with num_doors = %d trans = %s",num_doors,trans); 
		
	endfunction 
	virtual task drive_forward(); 

	endtask // drive_forward

endclass // hyundai 

class ford extends car; 

	function new(input int num_doors=2,input transmission_type trans=MANUAL); 
		super.new(num_doors,trans); 
		$display("%m Class is initialized with num_doors = %d trans = %s",num_doors,trans); 
	endfunction 	
 	virtual task drive_forward(); 
		$display("%m() is executing"); 
	endtask // drive_forward
endclass // ford

module top(); 
	ford ford_cl; 
	hyundai hyundai_cl ; 
	car car_cl; 

	initial 
	begin 
		ford_cl = new(4,1);
		hyundai_cl  = new(4,0);  // If this is assigned then casting to parent class is compatible. 
		//car_cl = new(2);
		//car_cl  = hyundai_cl  ; 
		if($cast(hyundai_cl, car_cl)) begin 
			$display("Classes are compatible"); 
		end else 
			$display("Classes are in-compatible"); 
				
		ford_cl.drive_forward();
	end 	

endmodule 

/* 
*	This test illustrates the implementation of factory design pattern in basic way. 
*	The factory design pattern solves the inheritance usage for creation
*	of various objects by taking type of the object needs to be created.  
*/ 

module tb(); 
	typedef enum {rd_tr=1,wr_tr=2,cache_en=3,buff_en=4} header_type; 
	
	virtual class packet; 
		rand bit [7:0] data;
		rand bit [7:0] addr; 
		rand header_type header; 	

		constraint header_type { 
			soft header == 4; 
		}; 

	endclass // packet 

	class wr_packet extends packet; 
		constraint header_c1{ header == 2; } 

		function new(); 
			$display("Initializing Write Packet" ); 	
		endfunction // new 

	endclass // wr_packet. 

	class rd_packet extends packet; 
		constraint header_c2 {  header == 1 ; } 
		
		function new(); 
			$display("Initializing Read Packet" ); 	
		endfunction // new 
	endclass // rd_packet. 	

	class cache_packet extends packet; 
		constraint header_c3 { header == 3 ; } 

		function new(); 
			$display("Initializing Cache Packet" ); 	
		endfunction // new 

	endclass // cache_packet 

	class factory_packet ; 
		static packet packet_i; 	

		// Instances of classes. 	
		static wr_packet wr_packet_i = new() ; 
		static rd_packet rd_packet_i = new() ; 
		static cache_packet cache_packet_i = new() ; 

		static function packet create_packet(string type_str); 

			if (type_str == "wr_pkt") begin 
				packet_i = wr_packet_i; 
			end
		       	else if (type_str == "rd_pkt") begin 
				packet_i = rd_packet_i; 
			end 
			else if (type_str == "cache_pkt") begin 
				packet_i = cache_packet_i; 
			end
			else 
				return null; 
			
			return packet_i; 			
		endfunction //create_packet. 

	endclass 
	
	packet packet_i;

	initial 
	begin 
		packet_i = factory_packet::create_packet("wr_pkt")    ;  

		if (packet_i.randomize()) begin 
			$display("Randomized the packet : %p",packet_i); 
		end else 
			$display("Randomization failed for wr packet = %p",packet_i); 

		packet_i = factory_packet::create_packet("wr_pkt")    ;  

		if (packet_i.randomize()) begin 
			$display("Randomized the packet : %p",packet_i); 
		end else 
			$display("Randomization failed for wr packet = %p",packet_i); 
		
		packet_i = factory_packet::create_packet("cache_pkt")    ;  

		if (packet_i.randomize()) begin 
			$display("Randomized the packet : %p",packet_i); 
		end else 
			$display("Randomization failed for wr packet = %p",packet_i); 

	end 

endmodule 
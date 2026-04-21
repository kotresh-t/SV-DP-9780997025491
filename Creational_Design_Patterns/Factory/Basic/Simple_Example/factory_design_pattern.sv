/* 
	Description: 
    Define an interface or abstract class for creating an object.
		Create concrete classes that implement this interface.
		Create a factory class/method that returns instances of these concrete classes based on given information.
*/ 

module tb(); 

  // Define an interface or abstract class for creating an object.
  virtual class simple_packet; 
    rand bit [7:0] data; 
    rand bit [7:0] addr; 
    rand bit  	   rd_wr_en; 
  endclass // simple_packet. 
 
  // Create concrete classes that implement this interface.
  class write_packet extends simple_packet; 
    
    constraint write_transer{ 
      		rd_wr_en == 0; 
    }
    
    function new(); 
      $display("Initializing Write Packet");   
    endfunction // new
  endclass //write_packet . 
  
  class read_packet extends simple_packet; 

    constraint read_transer{ 
          rd_wr_en == 1; 
    }
      
    function new(); 
        $display("Initializing Read Packet");   
    endfunction // new
  endclass //read_packet . 

  // Create a factory class/method that returns instances of these concrete classes based on given information.
  class factory_packet; 
    // Base Class. 
    static simple_packet packet_i ;
    
    // Static Instances of the classes. 
    static write_packet wr_packet_i   = new(); 
    static read_packet  rd_packet_i = new(); 
    
    static function simple_packet create_packet(string type_str); 
      if(type_str == "wr_packet")begin 
      	   packet_i = wr_packet_i ;
      end 
      if(type_str == "rd_packet") begin 
      	   packet_i = rd_packet_i ;     
      end
      
      return packet_i; 
      
    endfunction // create_packet
    
  endclass // factory_packet 
      
  // Usage of Factory Design Pattern. 
   simple_packet packet_i; 
      
   initial 
    begin 
       packet_i = factory_packet::create_packet("wr_packet");
       
       if(packet_i.randomize()) begin 
         $display("Randomized Write Packet = %p",packet_i); 
       end 
       
       packet_i = factory_packet::create_packet("rd_packet");
       
       if(packet_i.randomize()) begin 
         $display("Randomized Read Packet = %p",packet_i); 
       end 
    end 
  
endmodule // tb 
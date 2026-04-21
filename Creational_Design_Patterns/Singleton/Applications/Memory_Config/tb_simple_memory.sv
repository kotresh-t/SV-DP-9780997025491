/*///////////////////////////////////////////////////////////////////////////////
//File Name	: tb_simple_memory.sv
//Description	: Creates a TB for shared memory using singleton class                                                                               
//Args          :                                                                                           
//Author       	: Kotresh Ajjappa Tarale                                                
//Email         : tkotresh3@gmail.com                                           
///////////////////////////////////////////////////////////////////////////////*/
//
//

`ifndef TB_SIMPLE_MEMORY_SV
`define TB_SIMPLE_MEMORY_SV

// Include files. 
`include "memory_config_singleton_cl.sv"
`include "simple_memory.sv"

`timescale 1ns / 1ps

module tb_simple_memory;

    // Testbench variables
    logic clk;
    logic [31:0] data_in, data_out;
    logic wr_en,rd_en;
    logic [31:0] addr;
    logic [1023:0] mem; 

    // Instance of the memory module
    simple_memory mem_inst(.clk(clk), .data_in(data_in), .data_out(data_out),.addr(addr),.wr_en(wr_en),.rd_en(rd_en));

    // Singleton Pattern Class for global memory Configuration. 
    MemoryConfigSingleton cfg;
        
    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk 	= 0;
        data_in = 0;

        // Get memory configuration from the Singleton
	cfg = MemoryConfigSingleton::getInstance();
        $display("Memory Size: %0d, Access Time: %0d", cfg.memory_size, cfg.access_time);

        // Memory test logic
        // Perform write followed by read. 
	for(int i=0;i<cfg.memory_size;i=i+100)begin

		// Write Cycle 
		addr = i; 
		data_in = $urandom%1000;
		mem[addr] = data_in; 
		wr_en = 1; 
		#cfg.access_time; // This is not needed for our synchronous memory. As delays are not modeled . 
		//repeat(2) @(posedge clk); // We can use this instead. 
		wr_en = 0;	

		repeat(2) @(posedge clk);  

		// Read Cycle
		rd_en = 1; // address is already pointing to i 
		
		#cfg.access_time;
		
		if ( mem[addr] != data_out ) begin
			$display("Memory output doesn't match");
		end else 
		begin 
			$display("Data Match for Data in = %0d , Data out = %0d at time = %0d",data_in,data_out,$time);
		end 
	end

        #100;
        $finish;
    end

endmodule

`endif //TB_SIMPLE_MEMORY_SV


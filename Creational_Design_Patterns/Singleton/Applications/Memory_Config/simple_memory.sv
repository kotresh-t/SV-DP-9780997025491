/*///////////////////////////////////////////////////////////////////////////////
//File Name	: simple_memory.sv
//Description	: Creates a RTL for shared memory.                                                                              
//Args          :                                                                                           
//Author       	: Kotresh Ajjappa Tarale                                                
//Email         : tkotresh3@gmail.com                                           
///////////////////////////////////////////////////////////////////////////////*/
//
//
//
`ifndef SIMPLE_MEMORY_SV
`define SIMPLE_MEMORY_SV

module simple_memory #( parameter int MEM_SIZE = 1024, parameter int DATA_SIZE = 32 , parameter int ADDR_SIZE = 32) (
    input logic clk,
    input logic [DATA_SIZE-1:0] data_in,
    output logic [DATA_SIZE-1:0] data_out,
    input logic [ADDR_SIZE-1:0] address,
    input logic write_en,
    input logic read_en,
    input logic reset
);

    // Memory implementation (simple for example purposes)
    logic [MEM_SIZE-1:0] memory [MEM_SIZE-1:0];

    // Reset Memory
    always_ff @(posedge clk,reset) begin 
	if(reset) begin 
		for(int i=0; i< MEM_SIZE; i++)
			memory[i] = 0; 
	end 	
    end 

    // Perform read or writes. 
    always_ff @(posedge clk) begin
	if(rd_en) begin 
        	data_out <= memory[address];
	end
	
    end
    
    always_ff @(posedge clk) begin
	if(wr_en) begin 
		mem[address] = data_in ;
	end
    end 

endmodule

`endif //SIMPLE_MEMORY_SV


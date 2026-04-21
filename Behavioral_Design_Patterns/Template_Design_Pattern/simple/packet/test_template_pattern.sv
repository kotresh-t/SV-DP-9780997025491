// This is template for packet. 
`ifndef test_template_pattern_sv 
`define test_template_pattern_sv

virtual class packet_template;
    // Member variables common to all packets
   	bit[7:0] preamble;
    bit[31:0] crc;
	
	// Packet Types. 
	typedef enum {wr,rd,err} packet_type; 	
	packet_type pkt_type; 
	
	// packet size of 1k bytes. 	
	bit [7:0] pkt [1023:0]; 

	// packet header of eth packet. 
	bit [7:0] eth_packet; 
	bit [3:0] pci_packet; 
	bit [2:0] spi_packet; 

	// Packet Length
	bit [7:0] packet_length [15:0] ; 

	// Method to create packets of different packets. 
	function create_packet();	
		create_header(); 
		create_st_end(); 
		create_error(); 
		create_payload(); 	
	endfunction // create_packet

	// Method to create headers of different packets. 
	function create_header(); 
	endfunction // create_headers

	// Method to enable start or end synchronization. 
	function create_st_end(); 
	endfunction // create_st_end 

	// Method to create payload based on typically length field 
	virtual function void create_payload(); 
	endfunction // create_payload 

	// Method to create error scenarios of different packets. 
	function create_error(); 
	endfunction // create_errors

	// Run function to create packet,headers and errors. 
	function run(); 
		create_packet(); 
	endfunction // run 

endclass // packet_template

// Implement PCIePacket transaction. 
class PCIePacket extends packet_template;
    rand bit[15:0] requester_id;
    rand bit[7:0] tag;
    rand bit[31:0] address;
    rand bit valid_requester_id;
    rand bit valid_tag;
    rand bit valid_address;

    // Override methods for PCIe packet creation
    virtual function void create_header();
    	$display("Creating PCIe packet header");
    	requester_id = 16'h1234; // Example requester ID
    	tag = 8'hAB;             // Example tag
    endfunction

    virtual function void create_st_end();
    	// PCIe doesn't explicitly define start/end sync
    endfunction

    virtual function void create_error();
    	$display("Creating PCIe error detection");
    	crc = calculate_crc(); // Placeholder for CRC calculation
    endfunction

    virtual function void create_payload();
    	$display("Creating PCIe payload");
    	address = 32'hDEADBEEF; // Example address
    endfunction
    
	// Placeholder for crc function. 
    function int calculate_crc(); 
	    return (this.address[31:0] ^ this.tag ) + this.requester_id; 
    endfunction //create_crc. 

    // Override validation method for PCIe packet
    virtual function bit validate_packet();
    	$display("Validating PCIe packet");
    	valid_requester_id = (requester_id != 16'h0); // Simple validation example
    	valid_tag = (tag != 8'h0);                    // Simple validation example
    	valid_address = (address != 32'h0);           // Simple validation example
    	return valid_requester_id && valid_tag && valid_address;
    endfunction
endclass

// Implement EthernetPacket transaction. 
class EthernetPacket extends packet_template;
    bit[47:0] dest_mac;
    bit[47:0] src_mac;
    bit[15:0] ethertype;

    virtual function void create_header();
        $display("Creating Ethernet packet header");
        // Ethernet header creation logic
        dest_mac = 48'h112233445566;
        src_mac = 48'h665544332211;
        ethertype = 16'h0800; // Example Ethertype for IPv4
    endfunction

    virtual function void create_st_end();
        $display("Creating Ethernet start/end sync");
        // Ethernet start/end sync logic
        preamble = 8'h55; // Example preamble
    endfunction

    virtual function void create_error();
        $display("Creating Ethernet error detection");
        // Ethernet error detection logic
        crc = calculate_crc(); // Pseudo-function for CRC calculation
    endfunction

    // Placeholder for crc function. 
    function int calculate_crc(); 
		return (this.dest_mac[31:0]  ^ this.src_mac[31:0] ) + this.ethertype ; 
    endfunction //create_crc. 

    virtual function void create_payload();
        $display("Creating Ethernet payload");
        // Ethernet payload creation logic
        // Payload data would be added here
    endfunction
endclass


module testbench;

    PCIePacket pcie_packet;
    	
	initial begin
    	pcie_packet = new;
	    void'(pcie_packet.randomize()); 
    	pcie_packet.create_packet();
    	    
		if (pcie_packet.validate_packet()) begin
    	    $display("PCIe packet is valid.");
    	end else begin
    	    $display("PCIe packet is invalid.");
    	end
    	$finish;
    end

endmodule

`endif //  test_template_pattern_sv
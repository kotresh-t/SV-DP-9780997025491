/* Adapter design pattern used for conversion of one interface to another interface. 
 * In this example, we have an AXI interface and an AHB interface. The adapter class AhbToAxiAdapter allows us to use the AHB interface to perform operations that are expected by the AXI interface.
 * The adapter translates the AXI read/write operations into corresponding AHB read/write operations, allowing components designed for AXI to work with an AHB-based system without modification.
 * This is particularly useful in scenarios where we have legacy components or when we want to integrate different IP blocks that use different interfaces.
 * The testbench demonstrates how to use the adapter to perform read and write operations through the AXI interface, which internally uses the AHB interface.
 */

`ifndef test_adapter_pattern_sv
`define test_adapter_pattern_sv


// Define Target Interface. 
interface axi_interface(input logic clk, reset);
    // AXI-specific signals
    logic [31:0] axi_addr;
    logic [31:0] axi_wdata;
    logic axi_write_enable;
    logic [31:0] axi_rdata;
    logic axi_read_enable;

    modport master (
        output axi_addr, axi_wdata, axi_write_enable, axi_read_enable,
        input axi_rdata
    );
    task write(input logic [31:0] addr, input logic [31:0] data);
        axi_addr = addr;
        axi_wdata = data;
        axi_write_enable = 1;
        // Additional AXI write protocol handling
    endtask
    task read(input logic [31:0] addr, output logic [31:0] data);
        axi_addr = addr;
        axi_read_enable = 1;
        // Additional AXI read protocol handling
        data = axi_rdata;
    endtask
endinterface

// Define Source Interface. 
interface ahb_interface(input logic clk, reset);
    // AHB-specific signals
    logic [31:0] ahb_addr;
    logic [31:0] ahb_wdata;
    logic ahb_write_enable;
    logic [31:0] ahb_rdata;
    logic ahb_read_enable;

    modport master (
        output ahb_addr, ahb_wdata, ahb_write_enable, ahb_read_enable,
        input ahb_rdata
    );

    task write(input logic [31:0] addr, input logic [31:0] data);
        ahb_addr = addr;
        ahb_wdata = data;
        ahb_write_enable = 1;
        // Additional AHB write protocol handling
    endtask

    task read(input logic [31:0] addr, output logic [31:0] data);
        ahb_addr = addr;
        ahb_read_enable = 1;
        // Additional AHB read protocol handling
        data = ahb_rdata;
    endtask
endinterface

class AhbToAxiAdapter;
    virtual axi_interface axi;
    virtual ahb_interface ahb;

    function new(virtual axi_interface axi, virtual ahb_interface ahb);
        this.axi = axi;
        this.ahb = ahb;
    endfunction

    // Adapter write method
    task write(input logic [31:0] addr, input logic [31:0] data);
        // Translate AXI write to AHB write
        ahb.write(addr, data);
    endtask

    // Adapter read method
    task read(input logic [31:0] addr, output logic [31:0] data);
        // Translate AXI read to AHB read
        ahb.read(addr, data);
    endtask
endclass


module tb();
    // Instantiate interfaces
    axi_interface axi_intf();
    ahb_interface ahb_intf();
    AhbToAxiAdapter adapter = new(axi_intf, ahb_intf);

    initial begin
        // Use adapter to perform write/read operations
        logic [31:0] read_data;
        adapter.write(32'h0000_0000, 32'h1234_5678); // Example write
        adapter.read(32'h0000_0000, read_data);      // Example read
    end
endmodule

`endif // test_adapter_pattern_sv
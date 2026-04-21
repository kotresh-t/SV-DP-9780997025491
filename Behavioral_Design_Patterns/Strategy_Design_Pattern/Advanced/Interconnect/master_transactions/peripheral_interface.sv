// Target Interface for Peripherals
interface PeripheralInterface;
    task receive_data(bit [31:0] address, bit [31:0] data);
        $display("Peripheral Interface: Received Data = %h at Address = %h", data, address);
    endtask
endinterface

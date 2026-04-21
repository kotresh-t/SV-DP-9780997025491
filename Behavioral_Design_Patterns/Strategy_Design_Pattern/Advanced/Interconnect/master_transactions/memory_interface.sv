interface MemoryInterface;
    task receive_data(bit [31:0] address, bit [31:0] data);
        $display("Memory Interface: Received Data = %h at Address = %h", data, address);
    endtask
endinterface


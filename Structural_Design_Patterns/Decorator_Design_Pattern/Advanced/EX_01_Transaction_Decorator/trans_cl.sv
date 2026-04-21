`ifndef transaction_sv
`define transaction_sv


class transaction;
    bit [31:0] addr;
    bit [31:0] data;

    function new(bit [31:0] address, bit [31:0] data);
        this.addr = address;
        this.data = data;
    endfunction

    virtual task run();
        $display("Running Transaction at Addr: %d Data: %d", addr, data);
        addr = 100; 
        data = 200;
    endtask
endclass

`endif // transaction_sv

`ifndef transaction_sv
`define transaction_sv

class Transaction;
    bit [31:0] addr;
    bit [31:0] data;

    function new(bit [31:0] address, bit [31:0] data);
        this.addr = address;
        this.data = data;
    endfunction

    virtual task run();
        $display("Running Transaction at Addr: %h Data: %h", addr, data);
    endtask
endclass

`endif // transaction_sv

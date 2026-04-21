class AXITransaction extends TransactionStrategy;
    bit [31:0] address;
    bit [3:0] len;  // Burst length
    bit [2:0] size; // Burst size
    bit [1:0] burst; // Burst type
    bit [31:0] data;

    function new(bit [31:0] addr, bit [3:0] ln, bit [2:0] sz, bit [1:0] brst, bit [31:0] dat);
        address = addr;
        len = ln;
        size = sz;
        burst = brst;
        data = dat;
    endfunction

    // Dummy execute transaction method
    function void execute();
        $display("AXI Transaction: Addr %h, Len %d, Size %d, Burst %d, Data %h", address, len, size, burst, data);
    endfunction
endclass


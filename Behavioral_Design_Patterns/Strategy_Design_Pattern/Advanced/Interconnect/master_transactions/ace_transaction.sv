class ACETransaction extends TransactionStrategy;
    bit [31:0] address;
    bit [3:0] len;  // Burst length
    bit [2:0] size; // Burst size
    bit [1:0] burst; // Burst type
    bit [31:0] data;

    // Additional coherency fields can be defined here

    function new(bit [31:0] addr, bit [3:0] ln, bit [2:0] sz, bit [1:0] brst, bit [31:0] dat);
        super.new(addr, ln, sz, brst, dat);
        // Initialize coherency fields here
    endfunction

    // Override or extend execute to include coherency operations
    function void execute();
        super.execute();
        // Additional coherency logic
    endfunction
endclass


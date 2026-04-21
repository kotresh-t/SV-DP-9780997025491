class AXIStreamingTransaction extends TransactionStrategy;
    bit [31:0] data;
    bit valid;
    bit ready;
    bit last;

    function new(bit [31:0] dat, bit lst);
        data = dat;
        valid = 1'b1; // Assume data always valid
        ready = 1'b0; // Assume not ready initially
        last = lst;
    endfunction

    // Dummy execute transaction method
    function void execute();
        $display("AXI Streaming Data: %h, Last: %b", data, last);
    endfunction

endclass


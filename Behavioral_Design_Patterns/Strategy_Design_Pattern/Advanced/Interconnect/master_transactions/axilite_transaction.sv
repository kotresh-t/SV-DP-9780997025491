// AXI Lite transaction strategy
class AXILiteTransaction extends TransactionStrategy;
    bit [31:0] address;
    bit [31:0] data;

    function void setup(bit [31:0] addr, bit [31:0] dat);
        address = addr;
        data = dat;
    endfunction

    task execute();
        $display("AXI Lite Transaction: Address = %h, Data = %h", address, data);
    endtask

    function bit [31:0] get_address();
        return address;
    endfunction

    function bit [31:0] get_data();
        return data;
    endfunction
endclass

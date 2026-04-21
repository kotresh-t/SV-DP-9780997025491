// sequential_address_strategy.sv
class sequential_address_strategy extends uvm_object implements address_strategy;

logic [31:0] current_addr;

`uvm_object_utils(sequential_address_strategy)

    function new(string name = "sequential_address_strategy");
        super.new(name);
        reset();
    endfunction

    virtual function logic [31:0] next_address();
        current_addr += 4; // Align to 4-byte boundary
        return current_addr;
    endfunction

    virtual function void reset();
        current_addr = 32'h0000_0000;
    endfunction

endclass
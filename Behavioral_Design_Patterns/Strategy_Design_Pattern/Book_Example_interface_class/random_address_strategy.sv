// random_address_strategy.sv
class random_address_strategy extends uvm_object implements address_strategy;
`uvm_object_utils(random_address_strategy)

    function new(string name = "random_address_strategy");
       super.new(name);
    endfunction

    virtual function logic [31:0] next_address();
       return $urandom();
    endfunction

    virtual function void reset();
      // No state to reset
    endfunction
endclass
// address_strategy.sv
interface class address_strategy;
    pure virtual function logic [31:0] next_address();
    pure virtual function void reset();
endclass

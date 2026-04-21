module Interconnect(TransactionStrategy transaction_strategy, MemoryInterface mem_interface, PeripheralInterface peri_interface);
    function void route_transaction();
        transaction_strategy.execute();  // Execute the transaction
        bit [31:0] addr = transaction_strategy.get_address();
        bit [31:0] data = transaction_strategy.get_data();

        if (addr >= 32'h0000_0000 && addr <= 32'h0FFF_FFFF) {
            mem_interface.receive_data(addr, data);
        } else if (addr >= 32'h1000_0000 && addr <= 32'h1FFF_FFFF) {
            peri_interface.receive_data(addr, data);
        } else {
            $display("Address %h not in any mapped range", addr);
        }
    endfunction
endmodule


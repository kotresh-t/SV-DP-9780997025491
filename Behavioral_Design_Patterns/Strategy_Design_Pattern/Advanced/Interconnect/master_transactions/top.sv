module Top;
    // Instantiate transaction strategies
    TransactionStrategy transaction;
    AXILiteTransaction axi_lite();
    AXITransaction axi();  // Assuming AXITransaction is another class you defined similarly

    // Instantiate target interfaces
    MemoryInterface mem_intf();
    PeripheralInterface peri_intf();

    // Instantiate the interconnect
    Interconnect ic;

    initial begin
        // Select the transaction strategy based on some criteria (simplified here)
        if (some_condition) {
            transaction = axi_lite;
        } else {
            transaction = axi;
        }

        // Setup and route a transaction
        transaction.setup(32'h0000_1000, 32'hDEAD_BEEF);
        ic.transaction_strategy = transaction;
        ic.route_transaction();
    end
endmodule


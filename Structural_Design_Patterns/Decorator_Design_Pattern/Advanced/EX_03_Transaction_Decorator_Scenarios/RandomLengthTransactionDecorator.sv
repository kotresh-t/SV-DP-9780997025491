
`ifndef RandomLengthTransactionDecorator_SV
`define RandomLengthTransactionDecorator_SV

class RandomLengthTransactionDecorator extends TransactionDecorator;
    function new(Transaction transaction);
        super.new(transaction);
    endfunction

    virtual task run();
        bit [31:0] original_length = transaction.data; // Assume 'data' includes length info
        bit [31:0] random_length = $urandom_range(1, 1024); // Generate a random length

        if (pre_callback != null) begin
            pre_callback.execute(transaction.addr, transaction.data);
        end

        $display("[RANDOM-LENGTH-DECORATOR] Randomizing Transaction Length from %0d to %0d", original_length, random_length);
        transaction.data = random_length; // Set random length

        transaction.run();

        if (post_callback != null) begin
            post_callback.execute(transaction.addr, transaction.data);
        end
    endtask
endclass

`endif // RandomLengthTransactionDecorator_SV


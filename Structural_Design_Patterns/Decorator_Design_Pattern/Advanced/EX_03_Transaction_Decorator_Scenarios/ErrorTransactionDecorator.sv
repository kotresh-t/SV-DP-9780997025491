`ifndef ErrorTransactionDecorator_SV
`define ErrorTransactionDecorator_SV

class ErrorTransactionDecorator extends TransactionDecorator;
    bit introduce_error; // Flag to introduce error

    function new(Transaction transaction, bit introduce_error = 1'b1);
        super.new(transaction);
        this.introduce_error = introduce_error;
    endfunction

    virtual task run();
        if (pre_callback != null) begin
            pre_callback.execute(transaction.addr, transaction.data);
        end

        if (introduce_error) begin
            $display("[ERROR-DECORATOR] Introducing Error in Transaction at Addr: %h", transaction.addr);
            $display("[ERROR-DECORATOR] Original data: %h, Corrupting...", transaction.data);
            transaction.data = '1; // Corrupt data to simulate error
        end

        transaction.run();

        if (post_callback != null) begin
            post_callback.execute(transaction.addr, transaction.data);
        end
    endtask
endclass

`endif // ErrorTransactionDecorator_SV


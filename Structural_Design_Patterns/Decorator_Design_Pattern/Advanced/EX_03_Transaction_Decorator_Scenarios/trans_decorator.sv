`ifndef trans_decorator_sv
`define trans_decorator_sv


class TransactionDecorator;

    Transaction transaction;
    callback_cl pre_callback;
    callback_cl post_callback;

    function new(Transaction transaction);
        this.transaction = transaction;
    endfunction

    function void set_pre_callback(callback_cl cb);
        pre_callback = cb;
    endfunction

    function void set_post_callback(callback_cl cb);
        post_callback = cb;
    endfunction

    virtual task run();
        if (pre_callback != null) begin
            pre_callback.execute(transaction.addr, transaction.data);
        end

        transaction.run();

        if (post_callback != null) begin
            post_callback.execute(transaction.addr, transaction.data);
        end
    endtask

endclass

`endif // trans_decorator_sv


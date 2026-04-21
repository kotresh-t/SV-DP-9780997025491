`ifndef test_decorator_sv
`define test_decorator_sv

module test_decorator;

`include "transaction.sv"
`include "callback_cl.sv"
`include "trans_decorator.sv" 

    Transaction base_trans;
    TransactionDecorator decorated_trans;
    pre_callback_cl pre_cb;
    post_callback_cl  post_cb;

    initial begin
        base_trans = new(32'hAABBCCDD, 32'h12345678);
        pre_cb = new();
        post_cb = new();

        decorated_trans = new(base_trans);
        decorated_trans.set_pre_callback(pre_cb);
        decorated_trans.set_post_callback(post_cb);

        $display("=== Starting Decorator Pattern Test ===");
        decorated_trans.run();
        $display("=== Test Complete ===");
    end
endmodule // test_decorator

`endif // test_decorator_sv 
`ifndef test_decorators_sv
`define test_decorators_sv
/* 
=== Running basic decorated transaction ===
# [PRE-CALLBACK] Preparing transaction at Address: aabbccdd
# [PRE-CALLBACK] Data payload: 12345678
# Running Transaction at Addr: aabbccdd Data: 12345678
# [POST-CALLBACK] Transaction completed at Address: aabbccdd
# [POST-CALLBACK] Final data: 12345678
#
# === Running error transaction ===
# [PRE-CALLBACK] Preparing transaction at Address: aabbccdd
# [PRE-CALLBACK] Data payload: 12345678
# [ERROR-DECORATOR] Introducing Error in Transaction at Addr: aabbccdd
# [ERROR-DECORATOR] Original data: 12345678, Corrupting...
# Running Transaction at Addr: aabbccdd Data: ffffffff
# [POST-CALLBACK] Transaction completed at Address: aabbccdd
# [POST-CALLBACK] Final data: ffffffff
#
# === Running random length transaction ===
# [PRE-CALLBACK] Preparing transaction at Address: aabbccdd
# [PRE-CALLBACK] Data payload: ffffffff
# [RANDOM-LENGTH-DECORATOR] Randomizing Transaction Length from 4294967295 to 953
# Running Transaction at Addr: aabbccdd Data: 000003b9
# [POST-CALLBACK] Transaction completed at Address: aabbccdd
# [POST-CALLBACK] Final data: 000003b9
#
# === All Tests Complete ===
*/




module test_decorators;

`include "transaction.sv"
`include "callback_cl.sv"
`include "trans_decorator.sv" 
`include "ErrorTransactionDecorator.sv" 
`include "RandomLengthTransactionDecorator.sv" 

    Transaction base_trans;
    TransactionDecorator basic_decorated_trans;
    ErrorTransactionDecorator error_trans;
    RandomLengthTransactionDecorator random_length_trans;
    pre_callback_cl pre_cb;
    post_callback_cl post_cb;

    initial begin
        base_trans = new(32'hAABBCCDD, 32'h12345678);
        pre_cb = new();
        post_cb = new();

        // Basic decorated transaction
        basic_decorated_trans = new(base_trans);
        basic_decorated_trans.set_pre_callback(pre_cb);
        basic_decorated_trans.set_post_callback(post_cb);

        // Error transaction
        error_trans = new(base_trans, 1'b1);
        error_trans.set_pre_callback(pre_cb);
        error_trans.set_post_callback(post_cb);

        // Random length transaction
        random_length_trans = new(base_trans);
        random_length_trans.set_pre_callback(pre_cb);
        random_length_trans.set_post_callback(post_cb);

        // Run transactions
        $display("=== Running basic decorated transaction ===");
        basic_decorated_trans.run();

        $display("\n=== Running error transaction ===");
        error_trans.run();

        $display("\n=== Running random length transaction ===");
        random_length_trans.run();
        
        $display("\n=== All Tests Complete ===");
    end

endmodule // test_decorators

`endif // test_decorators_sv


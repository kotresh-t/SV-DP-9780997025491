`ifndef test_decorator_sv
`define test_decorator_sv
/* 
# === Starting Decorator Pattern Test ===
# [PRE-CALLBACK] Preparing transaction at Address: aabbccdd
# [PRE-CALLBACK] Data payload: 12345678
# Running Transaction at Addr: 2864434397 Data:  305419896
# [POST-CALLBACK] Transaction completed at Address:        100
# [POST-CALLBACK] Final data:        200
transaction → decorated with → pre_callback & post_callback → task callbacks
                                                                   ↓
                                                            $display output
*/ 

module test_decorator;

    `include "trans_cl.sv" 
    `include "trans_decorator.sv"

    // Test variables (callback classes are defined in trans_decorator.sv)
    pre_callback print_pre;
    post_callback print_post;
    trans_decorator_cl trans;

    initial begin
        print_pre = new(); 
        print_post = new(); 

        trans = new(32'hAABBCCDD, 32'h12345678);

        trans.set_callbacks(print_pre, print_post);
    
        $display("=== Starting Decorator Pattern Test ===");
        trans.run();
        $display("=== Test Complete ===");
    end
endmodule

`endif // test_decorator_sv
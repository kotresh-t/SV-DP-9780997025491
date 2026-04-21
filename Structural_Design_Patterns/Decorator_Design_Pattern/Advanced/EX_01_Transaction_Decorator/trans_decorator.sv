`ifndef trans_decorator_sv
`define trans_decorator_sv

// Abstract callback base class
virtual class callback_base;
    pure virtual task execute(bit [31:0] address, bit [31:0] data);
endclass

// Callback Class implementations
class pre_callback extends callback_base;
    virtual task execute(bit [31:0] address, bit [31:0] data);
        $display("[PRE-CALLBACK] Preparing transaction at Address: %h", address);
        $display("[PRE-CALLBACK] Data payload: %h", data);
    endtask
endclass

class post_callback extends callback_base;
    virtual task execute(bit [31:0] address, bit [31:0] data);
        $display("[POST-CALLBACK] Transaction completed at Address: %d", address);
        $display("[POST-CALLBACK] Final data: %d", data);
    endtask
endclass

// Transaction class with callback support
class trans_decorator_cl extends transaction; 

    // Callback object members
    pre_callback pre_callback_obj;
    post_callback post_callback_obj;    
    
    function new(bit [31:0] address, bit [31:0] data);
        super.new(address, data);
    endfunction

    // Method to set callbacks (using generic callback_base references)
    function void set_callbacks(pre_callback pre,  post_callback post);
        pre_callback_obj = pre;
        post_callback_obj = post;
    endfunction

    virtual task run();
        if (pre_callback_obj != null) begin
            pre_callback_obj.execute(addr, data);
        end

        super.run();    // Modified data from run() call. 

        if (post_callback_obj != null) begin
            post_callback_obj.execute(addr, data);
        end
    endtask	

endclass // trans_decorator_cl


`endif // trans_decorator_sv

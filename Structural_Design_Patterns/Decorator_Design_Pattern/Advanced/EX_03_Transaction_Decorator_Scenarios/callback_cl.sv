`ifndef callback_sv
`define callback_sv

// Abstract callback base class
virtual class callback_cl; 
    pure virtual task execute(bit [31:0] addr, bit [31:0] data); 
endclass // callback_cl 

class pre_callback_cl extends callback_cl; 
    virtual task execute(bit [31:0] addr, bit [31:0] data); 
        $display("[PRE-CALLBACK] Preparing transaction at Address: %h", addr); 
        $display("[PRE-CALLBACK] Data payload: %h", data); 
    endtask 
endclass // pre_callback_cl 

class post_callback_cl extends callback_cl; 
    virtual task execute(bit [31:0] addr, bit [31:0] data); 
        $display("[POST-CALLBACK] Transaction completed at Address: %h", addr); 
        $display("[POST-CALLBACK] Final data: %h", data); 
    endtask
endclass // post_callback_cl 

`endif // callback_sv 

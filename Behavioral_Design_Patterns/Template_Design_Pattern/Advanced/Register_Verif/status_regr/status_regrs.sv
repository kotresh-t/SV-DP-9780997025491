
class status_reg1;
    bit operation_complete;
    function bit read();
        bit value = operation_complete;
        operation_complete = 0; // clear on read
        return value;
    endfunction

    function void reset();
        operation_complete = 0;
    endfunction
endclass

////////// status_reg2
class status_reg2;
    bit error_flag;

    function bit read();
        bit value = error_flag;
        error_flag = 0; // clear on read
        return value;
    endfunction

    function void reset();
        error_flag = 0;
    endfunction
endclass

////////// status _register _block
class status_register_block;
    status_reg1 reg1;
    status_reg2 reg2;

    function new();
        reg1 = new();
        reg2 = new();
    endfunction

endclass

typedef enum {mode0, mode1, mode2} operational_mode;

class control_reg1;
    bit enable_operation;
    function void write(bit value);
        enable_operation = value;
    endfunction

    function bit read();
        return enable_operation;
    endfunction

    function void reset();
        enable_operation = 0;
    endfunction
endclass

// control_reg2
class control_reg2;
    
    operational_mode mode_regr; 
    
    function void write(operational_mode mode);
        mode_regr = mode;
    endfunction

    function operational_mode read();
        return mode_regr;
    endfunction

    function void reset();
        mode_regr = mode0;
    endfunction
endclass

// control register _block
class control_register_block;
    control_reg1 reg1;
    control_reg2 reg2;

    function new();
        reg1 = new();
        reg2 = new();
    endfunction

endclass


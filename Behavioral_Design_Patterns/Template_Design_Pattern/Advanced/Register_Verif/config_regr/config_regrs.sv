typedef enum {spi, i2c} interface_mode;
typedef enum {low, medium_1, high} data_rate;

class config_reg1;
    
    data_rate rate_regr; 

    function void write(data_rate rate);
        rate_regr = rate;
    endfunction

    function data_rate read();
        return rate_regr;
    endfunction

    function void reset();
        rate_regr = medium_1; // default rate
    endfunction

endclass

////////  config_reg2
class config_reg2;
    
    interface_mode imode_regr; 

    function void write(interface_mode mode);
        imode_regr = mode;
    endfunction

    function interface_mode read();
        return imode_regr;
    endfunction

    function void reset();
        imode_regr = spi; // default mode
    endfunction
endclass




///////  configuration _register _block : 
class config_register_block;
    config_reg1 reg1;
    config_reg2 reg2;

    function new();
        reg1 = new();
        reg2 = new();
    endfunction

endclass


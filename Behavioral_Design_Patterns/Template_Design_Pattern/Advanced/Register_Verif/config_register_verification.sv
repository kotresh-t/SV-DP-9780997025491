//`include "register_verification_template.sv" 
//`include "config_regr/config_regrs.sv"

class config_register_verification extends register_verification;
    config_register_block config_reg_block;

    function new();
        config_reg_block = new();
    endfunction

    virtual function void perform_common_verification();
        // common verification steps for configuration registers
    endfunction

    virtual function void perform_specific_verification();
        // specific verification for config_reg1
        config_reg_block.reg1.write(data_rate'(2));
        assert(config_reg_block.reg1.read() == data_rate'(2));
        config_reg_block.reg1.reset();
        assert(config_reg_block.reg1.read() == data_rate'(1));

        // specific verification for config_reg2
        config_reg_block.reg2.write(interface_mode'(1));
        assert(config_reg_block.reg2.read() == interface_mode'(1));
        config_reg_block.reg2.reset();
        assert(config_reg_block.reg2.read() == interface_mode'(0));
    endfunction
endclass


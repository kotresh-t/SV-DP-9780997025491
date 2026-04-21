//`include "register_verification_template.sv" 
//`include "status_regr/status_regrs.sv" 

class status_register_verification extends register_verification;
    status_register_block status_reg_block;

    function new();
        status_reg_block = new();
    endfunction

    virtual function void perform_common_verification();
        // common verification steps for status registers
    endfunction

    virtual function void perform_specific_verification();
        // specific verification for status_reg1
        status_reg_block.reg1.operation_complete = 1;
        assert(status_reg_block.reg1.read() == 1);
        assert(status_reg_block.reg1.read() == 0); // auto-clear check

        // specific verification for status_reg2
        status_reg_block.reg2.error_flag = 1;
        assert(status_reg_block.reg2.read() == 1);
        assert(status_reg_block.reg2.read() == 0); // auto-clear check
    endfunction

endclass


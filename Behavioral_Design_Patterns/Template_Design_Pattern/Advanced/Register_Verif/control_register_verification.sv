
class control_register_verification extends register_verification;
    control_register_block control_reg_block;

    function new();
        control_reg_block = new();
    endfunction

    virtual function void perform_common_verification();
        // common verification steps for control registers
    endfunction

    virtual function void perform_specific_verification();
        // specific verification for control_reg1
        control_reg_block.reg1.write(1);
        assert(control_reg_block.reg1.read() == 1);
        control_reg_block.reg1.reset();
        assert(control_reg_block.reg1.read() == 0);

        // specific verification for control_reg2
        control_reg_block.reg2.write(operational_mode'(1));
        assert(control_reg_block.reg2.read() == operational_mode'(1));
        control_reg_block.reg2.reset();
        assert(control_reg_block.reg2.read() == operational_mode'(0));
    endfunction
endclass


`ifndef REGISTER_VERIFICATION_TEMPLATE_SV
`define REGISTER_VERIFICATION_TEMPLATE_SV

virtual class register_verification;

    // common verification steps
    virtual function void perform_common_verification();
        // implementation of common verification steps
    endfunction

    // abstract method for specific verification
    virtual function void perform_specific_verification();
    endfunction

    // template method
    function void verify_register();
        perform_common_verification();
        perform_specific_verification(); // implemented in derived classes
    endfunction

endclass

`endif // REGISTER_VERIFICATION_TEMPLATE_SV

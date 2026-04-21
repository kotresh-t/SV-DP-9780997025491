`include "register_package.sv"

module testbench;

import register_package::*; 

// Instantiate the verification classes
control_register_verification ctrl_reg_verif;
status_register_verification status_reg_verif;
config_register_verification config_reg_verif;

initial begin
    // Create instances of verification classes
    ctrl_reg_verif = new();
    status_reg_verif = new();
    config_reg_verif = new();

    // Perform verification for control registers
    $display("Starting Control Register Verification");
    ctrl_reg_verif.verify_register();
    $display("Control Register Verification Completed");

    // Perform verification for status registers
    $display("Starting Status Register Verification");
    status_reg_verif.verify_register();
    $display("Status Register Verification Completed");

    // Perform verification for configuration registers
    $display("Starting Configuration Register Verification");
    config_reg_verif.verify_register();
    $display("Configuration Register Verification Completed");

    $display("All Verifications Completed");
end

endmodule


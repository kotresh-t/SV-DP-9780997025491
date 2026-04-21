`timescale 1ns / 1ps
import uvm_pkg::*;
`include "clock_reset_controller_singleton.sv"
`include "example_design.sv"

module tb_singleton_clock_reset;
    ClockResetControllerSingleton clock_reset_ctrl = ClockResetControllerSingleton::getInstance(10, 40); // Fast: 100 MHz, Slow: 25 MHz
    logic fast_clock_activity, slow_clock_activity;

    initial begin
        // Start clock generation tasks
        fork
            clock_reset_ctrl.run_fast_clock();
            clock_reset_ctrl.run_slow_clock();
        join_none

        // Assert and deassert reset
        clock_reset_ctrl.assert_reset();

        // Rest of the testbench logic
        // ...

        // Finish the simulation after a certain period
        #1000;
        $finish;
    end

    example_design uut (
        .clk_fast(clock_reset_ctrl.clk_fast),
        .clk_slow(clock_reset_ctrl.clk_slow),
        .rst(clock_reset_ctrl.rst),
        .fast_clock_activity(fast_clock_activity),
        .slow_clock_activity(slow_clock_activity)
    );

    // Additional testbench components
    // ...

endmodule


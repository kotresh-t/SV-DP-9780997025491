`ifndef TB_M
`define TB_M

module testbench;
`include "strategy.sv" 

  Tester tester = new();
  FunctionalTest func_test = new();
  PerformanceTest perf_test = new();
  ErrorScenarioTest err_test = new();

  initial begin
    // Set strategy and perform tests
    tester.set_strategy(func_test);
    tester.perform_tests();

    tester.set_strategy(perf_test);
    tester.perform_tests();

    tester.set_strategy(err_test);
    tester.perform_tests();
  end
endmodule

`endif // TB_M

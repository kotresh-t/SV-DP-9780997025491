`ifndef STRATEGY_CL
`define STRATEGY_CL

// Strategy Interface
virtual class VerificationStrategy;
  pure virtual function void execute();
endclass

// Functional Verification Strategy
class FunctionalTest extends VerificationStrategy;
  function void execute();
    $display("Executing functional verification.");
    // Functional test implementation
  endfunction
endclass

// Performance Testing Strategy
class PerformanceTest extends VerificationStrategy;
  function void execute();
    $display("Executing performance testing.");
    // Performance test implementation
  endfunction
endclass

// Error Scenario Testing Strategy
class ErrorScenarioTest extends VerificationStrategy;
  function void execute();
    $display("Executing error scenario testing.");
    // Error test implementation
  endfunction
endclass

// Context class
class Tester;
  local VerificationStrategy strategy;

  function void set_strategy(VerificationStrategy new_strategy);
    this.strategy = new_strategy;
  endfunction

  function void perform_tests();
    this.strategy.execute();
  endfunction
endclass

`endif // STRATEGY_CL

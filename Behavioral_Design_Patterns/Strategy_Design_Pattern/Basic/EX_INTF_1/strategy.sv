`ifndef STRATEGY_CL
`define STRATEGY_CL

// --------------------------------------------------------------------------
// Description: 
// This is same as EX_1 except it uses concept of interface class similar to
// one available in JaVA classes. The interface class behaves similar to
// virtual class but allows implementations of multiple behavior or versions
// by supporting multi inheritance. 
// ---------------------------------------------------------------------------

// Strategy Interface
interface class VerificationStrategy;
  /** 
    * Note that the function needs to be pure virtual function 
    * allowing it to be only implemented by extended classes. 
  */ 
  pure virtual function void execute();

endclass

// Functional Verification Strategy
class FunctionalTest implements VerificationStrategy;
  
  virtual function void execute();
    $display("Executing functional verification.");
    // Functional test implementation
  endfunction

endclass

// Performance Testing Strategy
class PerformanceTest implements VerificationStrategy;
  
  virtual function void execute();
    $display("Executing performance testing.");
    // Performance test implementation
  endfunction

endclass

// Error Scenario Testing Strategy
class ErrorScenarioTest implements VerificationStrategy;
  
  virtual function void execute();
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

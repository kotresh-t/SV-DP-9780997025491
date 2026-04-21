`ifndef testbench_sv
`define testbench_sv
/* Results: 

# UVM_INFO @ 0: reporter [RNTST] Running test my_test...
# UVM_INFO uvm_my_driver.sv(51) @ 0: uvm_test_top.env.agt.drv [uvm_test_top.env.agt.drv] [Decorated] Driving transaction with data: 51 [PerfMetrics enabled]
# UVM_INFO uvm_my_driver.sv(51) @ 0: uvm_test_top.env.agt.drv [uvm_test_top.env.agt.drv] [Decorated] Driving transaction with data: 195 [PerfMetrics enabled]
# UVM_INFO uvm_my_driver.sv(51) @ 0: uvm_test_top.env.agt.drv [uvm_test_top.env.agt.drv] [Decorated] Driving transaction with data: 39 [PerfMetrics enabled]

*/ 

`include "UvmDecorator_pkg.sv"

// Top module for running the UVM test
module testbench;
  
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import uvm_decorator_pkg::*; 

    initial begin
        run_test("my_test");
    end
endmodule


`endif // testbench_sv

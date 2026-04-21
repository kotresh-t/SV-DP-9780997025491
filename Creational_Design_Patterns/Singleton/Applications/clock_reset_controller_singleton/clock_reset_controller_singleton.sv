`ifndef CLOCK_RESET_CONTROLLER_SINGLETON_SV
`define CLOCK_RESET_CONTROLLER_SINGLETON_SV

class ClockResetControllerSingleton;
    local static ClockResetControllerSingleton instance;
    bit clk_fast;
    bit clk_slow;
    bit rst;

    // Clock periods as parameters
    int fast_clk_period_ns;
    int slow_clk_period_ns;

    function new(int fast_clk_period = 10, int slow_clk_period = 40);
        fast_clk_period_ns = fast_clk_period;
        slow_clk_period_ns = slow_clk_period;
        clk_fast = 0;
        clk_slow = 0;
        rst = 1; // Active high reset
    endfunction

    static function ClockResetControllerSingleton getInstance(int fast_clk_period = 10, int slow_clk_period = 40);
        if (instance == null) begin
            instance = new(fast_clk_period, slow_clk_period);
        end
        return instance;
    endfunction

    // Clock generation methods
    task run_fast_clock();
        forever #(fast_clk_period_ns / 2) clk_fast = ~clk_fast;
    endtask

    task run_slow_clock();
        forever #(slow_clk_period_ns / 2) clk_slow = ~clk_slow;
    endtask

    // Reset control methods
    task assert_reset();
        rst = 1;
        #100; // Assert reset for a specific duration
        rst = 0;
    endtask

endclass

`endif // CLOCK_RESET_CONTROLLER_SINGLETON_SV


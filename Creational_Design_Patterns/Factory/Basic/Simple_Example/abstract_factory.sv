// Abstract factory with multiple creation methods
virtual class UIFactory;
    pure virtual function Button create_button();
    pure virtual function Window create_window();
    pure virtual function Checkbox create_checkbox();
endclass

// Concrete factories - each makes a FAMILY of products
class WindowsUIFactory extends UIFactory;
    function Button create_button();
        return new WindowsButton();      // Windows style
    endfunction
    function Window create_window();
        return new WindowsWindow();      // Windows style
    endfunction
    function Checkbox create_checkbox();
        return new WindowsCheckbox();    // Windows style
    endfunction
endclass

class MacUIFactory extends UIFactory;
    function Button create_button();
        return new MacButton();          // Mac style
    endfunction
    function Window create_window();
        return new MacWindow();          // Mac style
    endfunction
    function Checkbox create_checkbox();
        return new MacCheckbox();        // Mac style
    endfunction
endclass

// Usage
UIFactory factory = get_theme_factory("windows");
Button b = factory.create_button();       // WindowsButton
Window w = factory.create_window();       // WindowsWindow
Checkbox c = factory.create_checkbox();   // WindowsCheckbox
// All compatible — consistent theme

// ============================================================================
// Dependency Inversion Principle (DIP) - Example
// ============================================================================
// Problem (violates DIP): test directly depends on concrete driver class
// Instead of depending on abstraction, the test holds a concrete
// `axi_master_driver` reference which couples the test to a specific
// implementation and makes reuse and mocking harder.
//
// Instead, depend on an abstract interface (virtual interface) and
// inject the actual interface instance at runtime (via `uvm_config_db`
// or explicit assignment). This inverts the dependency: high-level
// test code depends on an abstraction rather than a concrete driver.

// Bad: concrete dependency
class my_test_bad extends uvm_test;
    // concrete dependency - tight coupling
    axi_master_driver drv;
    function new(string name = "my_test_bad", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// Good: depend on abstraction (virtual interface)
class my_test extends uvm_test;
    // abstraction via virtual interface - test depends on interface, not driver
    virtual axi_if vif;
    axi_master_driver drv;

    function new(string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // create driver as normal
        drv = axi_master_driver::type_id::create("drv", this);
        // obtain virtual interface instance from config DB (set by top-level testbench)
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not set in uvm_config_db")
        end
        // pass virtual interface to driver (driver should expose `virtual axi_if vif;`)
        drv.vif = vif;
    endfunction
endclass

// Top-level testbench example: instantiate interface and publish to config DB
module tb_top;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1;

    // DUT-facing AXI interface instance
    axi_if vif_inst(clk, rst);

    initial begin
        // publish virtual interface so UVM components can retrieve it
        uvm_config_db#(virtual axi_if)::set(null, "", "vif", vif_inst);
        // start UVM test
        run_test();
    end
endmodule

// Notes:
// - This demonstrates DIP: `my_test` depends on the `axi_if` abstraction.
// - The concrete `axi_if` instance is provided by the top-level testbench,
//   allowing the same `my_test` to run with different interface implementations
//   (e.g., a bus functional model, a mock, or a scoreboard stub).
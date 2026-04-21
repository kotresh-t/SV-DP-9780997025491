
// Abstract command interface
virtual class Command;
	virtual task execute(); 
	endtask
endclass

// Concrete command to run a basic test
class BasicTestCommand extends Command;
  virtual task execute();
    // Code to set up and run a basic test
    $display("Running basic test structure...");
    // Test structure code here
  endtask
endclass

// Concrete command to run an advanced test
class AdvancedTestCommand extends Command;
  virtual task execute();
    // Code to set up and run an advanced test
    $display("Running advanced test structure...");
    // Advanced test structure code here
  endtask
endclass

// Invoker class that executes the command
class TestBench;
  Command cmd;

  // Method to set the command
  function void setCommand(Command new_cmd);
    cmd = new_cmd;
  endfunction

  // Method to execute the command
  task runTest();
    cmd.execute();
  endtask
endclass

// Client code
module top;
  TestBench tb = new();
  BasicTestCommand 	basic_test;
  AdvancedTestCommand advanced_test; 

  initial begin
    basic_test    = new();
    advanced_test = new();

    // Set and run a basic test
    tb.setCommand(basic_test);
    tb.runTest();

    // Set and run an advanced test
    tb.setCommand(advanced_test);
    tb.runTest();

    #10 $finish;
  end
endmodule


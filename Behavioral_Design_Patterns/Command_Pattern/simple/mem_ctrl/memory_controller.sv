interface class ICommand;
  pure virtual task execute();
endclass 

module tb(); 

class MemoryController;
  // Method to perform a read operation
  function void performRead();
    $display("Performing read operation in Memory Controller");
    // Read operation logic here
  endfunction

  // Method to perform a write operation
  function void performWrite();
    $display("Performing write operation in Memory Controller");
    // Write operation logic here
  endfunction

  // Method to check the status of the Memory Controller
  function void checkStatus();
    $display("Checking status of Memory Controller");
    // Status check logic here
  endfunction
endclass

class ReadCommand implements ICommand;
  MemoryController memCtrl; // Assume MemoryController is a class

  function new(MemoryController memCtrl);
    this.memCtrl = memCtrl;
  endfunction

  virtual task execute();
    memCtrl.performRead(); // performRead() is a method in MemoryController
  endtask
endclass

class WriteCommand implements ICommand;
  MemoryController memCtrl;

  function new(MemoryController memCtrl);
    this.memCtrl = memCtrl;
  endfunction

  virtual task execute();
    memCtrl.performWrite();
  endtask
endclass

class StatusCheckCommand implements ICommand;
  MemoryController memCtrl;

  function new(MemoryController memCtrl);
    this.memCtrl = memCtrl;
  endfunction

  virtual task execute();
    memCtrl.checkStatus();
  endtask
endclass

class CommandExecutor;
  ICommand command_queue[$];

  function void addCommand(ICommand cmd);
    command_queue.push_back(cmd);
  endfunction

  task executeAll();
    foreach (command_queue[i]) begin
      command_queue[i].execute();
    end
  endtask
endclass

  MemoryController memCtrl = new();
  CommandExecutor executor = new();

  initial begin
    // Create command instances
    ReadCommand cmd; 
    StatusCheckCommand s_cmd; 
    WriteCommand w_cmd; 
    cmd = new(memCtrl); 
    executor.addCommand(cmd);
    w_cmd = new(memCtrl); 
    executor.addCommand(w_cmd);
    s_cmd = new(memCtrl); 
    executor.addCommand(s_cmd);

    // Execute all commands
    executor.executeAll();

    #100;
    $finish;
  end
endmodule







module testbench;
// Transaction types
typedef enum {READ, WRITE} transaction_type;

// Transaction class
class I2CTransaction;
    transaction_type type_i2c;
    byte address;
    byte data;

    function new(transaction_type type_i2c, byte address, byte data = 0);
      this.type_i2c = type_i2c;
      this.address = address;
      this.data = data;
    endfunction

  // Method to simulate a write operation
  task write(byte address, byte data);
    $display("I2C Write: Address = %0h, Data = %0h", address, data);
    // Simulate I2C write operation...
  endtask

  // Method to simulate a read operation
  task read(byte address, output byte data_out);
    data_out = data; // Example read data
    $display("I2C Read: Address = %0h, Data = %0h", address, data_out);
    // Simulate I2C read operation...
  endtask
  
endclass


interface class ICommand;
  pure virtual task execute();
endclass

// I2C Write Command
class WriteCommand implements ICommand;
  I2CTransaction transaction;

  function new(I2CTransaction transaction);
    this.transaction = transaction;
  endfunction

  virtual task execute();
    transaction.write(transaction.address, transaction.data);
  endtask
endclass

// I2C Read Command
class ReadCommand implements ICommand;
  I2CTransaction transaction;

  function new(I2CTransaction transaction);
    this.transaction = transaction;
  endfunction

  virtual task execute();
    transaction.read(transaction.address, transaction.data);
  endtask
endclass


class I2CController;
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


  i2c_if i2c_bus();
  I2CController controller = new();

  initial begin
    // Create I2C transactions and corresponding commands
    I2CTransaction write_txn;  
    I2CTransaction read_txn;   
    ReadCommand read_cmd; 
    WriteCommand write_cmd; 
    write_txn = new(WRITE, 8'h50, 8'hA5);
    read_txn = write_txn; // For simplicity, using the same transaction for read
    write_cmd = new(write_txn);
    read_cmd = new(read_txn);
    // Create and queue I2C transactions
    controller.addCommand(write_cmd);
    controller.addCommand(read_cmd);

    // Execute all commands
    controller.executeAll();

    #100;
    $finish;
  end
endmodule




//1. The Subject (Driver) - Just Broadcasts
//Code snippet
class my_driver extends uvm_driver;
  // The "mailbox" for broadcasting
  uvm_analysis_port #(my_trans) ap; 

  function void build_phase(uvm_phase phase);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    // ... driving logic ...
    ap.write(tr); // "I'm done with this trans, do what you want with it!"
  endtask
endclass

//2. The Observer (Checker) - Just Listens
//Code snippet
// uvm_subscriber is a built-in "Observer"
class my_checker extends uvm_subscriber #(my_trans);
  
  // This is the implementation of the Observer's "update" method
  virtual function void write(my_trans t);
    verify_behavior(t);
  endfunction
  
endclass
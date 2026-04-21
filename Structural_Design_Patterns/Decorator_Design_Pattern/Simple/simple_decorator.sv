/* Showcases usage of Decorator Design Pattern in SystemVerilog with composition of objects. 
  * We have a base monitor interface and a concrete monitor implementation. 
  * We then create a base decorator class that implements the monitor  interface.  
  * We can then create specific decorators (like coverage, logging, CRC) that extend the base decorator and add additional functionality while still delegating to the wrapped monitor.
  * This allows us to dynamically compose different behaviors on top of the basic monitor without modifying its code or creating a complex inheritance hierarchy.
*/ 

module decorator_tb;

//STEP 1. Transaction Definition
class bus_txn;

  rand bit [31:0] addr;
  rand bit [31:0] data;

  function new(bit [31:0] a = 0, bit [31:0] d = 0);
    addr = a;
    data = d;
  endfunction
endclass

//STEP 2. Monitor Interface (As Given)
interface class monitor_if;
  pure virtual function void write(bus_txn txn);
endclass

//STEP 3. Concrete Monitor
class basic_monitor implements monitor_if;

  virtual function void write(bus_txn txn);
    $display("[%0t] BASIC_MONITOR : addr=0x%0h data=0x%0h",  $time, txn.addr, txn.data);
  endfunction

endclass

//STEP 4. Base Decorator
class monitor_decorator implements monitor_if;
  protected monitor_if wrapped;

  function new(monitor_if m);
    wrapped = m;
  endfunction

  virtual function void write(bus_txn txn);
    wrapped.write(txn);
  endfunction
endclass

//STEP 5. Coverage Decorator
class coverage_decorator extends monitor_decorator;

  bit [31:0] txn_addr;

  covergroup cov;
    addr_cp : coverpoint txn.addr {
      bins low  = {[32'h0000:32'h0FFF]};
      bins high = {[32'h1000:32'hFFFF]};
    }
  endgroup

  function new(monitor_if m);
    super.new(m);
    cov = new();
  endfunction

  virtual function void write(bus_txn txn);
    txn_addr = txn.addr;
    super.write(txn);
    cov.sample();
    $display("[%0t] COVERAGE_DECORATOR : coverage sampled", $time);
  endfunction
endclass

//STEP 6. Logging Decorator (Optional but Illustrative)
class logging_decorator extends monitor_decorator;

  function new(monitor_if m);
    super.new(m);
  endfunction

  virtual function void write(bus_txn txn);
    $display("[%0t] LOGGING_DECORATOR : before write", $time);
    super.write(txn);
    $display("[%0t] LOGGING_DECORATOR : after write", $time);
  endfunction
endclass

//STEP 7. CRC / Check Decorator (Optional)
class crc_decorator extends monitor_decorator;

  function new(monitor_if m);
    super.new(m);
  endfunction

  virtual function void write(bus_txn txn);
    super.write(txn);
    if ((txn.addr ^ txn.data) == 32'hDEAD_BEEF)
      $display("[%0t] CRC_DECORATOR : suspicious pattern detected", $time);
  endfunction
endclass

  // Build decorator stack dynamically
  monitor_if monitor; 
  basic_monitor base_mon;
  crc_decorator crc_mon;
  coverage_decorator cov_mon;
  logging_decorator log_mon;
  bus_txn txn;

  initial begin
    
    // Step 1: base component
    base_mon = new;
    crc_mon = new(base_mon);
    cov_mon = new(crc_mon);
    log_mon = new(cov_mon);
    
    // Final decorated monitor
    monitor = log_mon;

    // Drive transactions
    repeat (5) begin
      txn = new($urandom_range(0, 32'h2000),   $urandom());
      monitor.write(txn);
      #10;
    end

    $display("---- TEST COMPLETE ----");
    $finish;
  end

endmodule

/* 
 [0] LOGGING_DECORATOR : before write
# [0] BASIC_MONITOR : addr=0x1084 data=0x9d0db966
# [0] COVERAGE_DECORATOR : coverage sampled
# [0] LOGGING_DECORATOR : after write
# [10] LOGGING_DECORATOR : before write
# [10] BASIC_MONITOR : addr=0x6a data=0x83956e46
# [10] COVERAGE_DECORATOR : coverage sampled
*/ 

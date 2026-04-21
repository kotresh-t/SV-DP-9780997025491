/* This example demonstrates the Chain of Responsibility design pattern in a verification context using SystemVerilog and UVM. 
 * We define a series of transaction handlers that perform various checks on bus transactions, such as protocol compliance, data integrity, ordering, performance, and assertions.
 * Each handler can either process the transaction or pass it to the next handler in the chain. This allows for flexible and modular verification logic.
 * We also demonstrate how to build a standard chain of handlers and use it within a verification environment to process transactions.
 * Finally, we show specific use cases such as filtering write transactions, handling scoreboard entries, and checking state transitions.
 */


module test_chain_of_responsibility;

`include "uvm_macros.svh"
import uvm_pkg::*;

// Define FSM states for assertion checker
typedef enum {IDLE, READING, WRITING, WAITING} fsm_state_e;

// Define command types
typedef enum {READ, WRITE} cmd_t;

// ============================================================================
// Bus Transaction Class
// ============================================================================
class bus_transaction extends uvm_sequence_item;
  `uvm_object_utils(bus_transaction)
  
  cmd_t command;
  logic [31:0] addr;
  logic [31:0] data;
  bit has_parity;
  bit has_latency_info;
  bit [7:0] parity;
  int latency;
  int sequence_num;
  logic [3:0] write_strobe;
  logic [31:0] expected_value;
  
  function new(string name = "bus_transaction");
    super.new(name);
  endfunction
endclass

// ============================================================================
// Interface for Transaction Handler
// ============================================================================
interface class itransaction_handler;
  pure virtual task process(bus_transaction txn);
  pure virtual function void set_successor(itransaction_handler next);
endclass

// ============================================================================
// Base Transaction Handler Class
// ============================================================================
class transaction_handler_base extends uvm_object implements itransaction_handler;
  `uvm_object_utils(transaction_handler_base)
  
  protected itransaction_handler successor;
  
  function new(string name = "transaction_handler_base");
    super.new(name);
  endfunction
  
  virtual function void set_successor(itransaction_handler next);
    successor = next;
  endfunction
  
  // Default chain traversal logic
  virtual task process(bus_transaction txn);
    if (can_handle(txn)) begin
      handle(txn);
    end
    if (successor != null) begin
      successor.process(txn);
    end
  endtask
  
  virtual function bit can_handle(bus_transaction txn);
    return 0;
  endfunction
  
  virtual task handle(bus_transaction txn);
    `uvm_fatal("HANDLER", "handle() not implemented in concrete handler")
  endtask
endclass

// ============================================================================
// Abstract Handler - Convenience base class
// ============================================================================
class transaction_handler extends transaction_handler_base;
    `uvm_object_utils(transaction_handler)
    
    function new(string name = "transaction_handler");
        super.new(name);
    endfunction

endclass

// ============================================================================
// Concrete Handlers
// ============================================================================

// Protocol Compliance Checker
class protocol_checker extends transaction_handler;
  `uvm_object_utils(protocol_checker)
  
  function new(string name="protocol_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return 1;
  endfunction
  
  task handle(bus_transaction txn);
    `uvm_info("PROTOCOL", "Protocol check passed", UVM_MEDIUM)
  endtask
endclass

// Data Integrity Checker
class data_checker extends transaction_handler;
  `uvm_object_utils(data_checker)
  
  function new(string name="data_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return (txn.command == WRITE) && txn.has_parity;
  endfunction
  
  task handle(bus_transaction txn);
    bit parity = 0;
    `uvm_info("DATA_CHK", "Verifying data integrity", UVM_MEDIUM)
    foreach (txn.data[i]) 
      parity ^= txn.data[i];
    assert (parity == txn.parity) else 
      `uvm_error("DATA_CHK", "Parity mismatch");
  endtask
endclass

// Ordering Checker (ensures in-order delivery)
class ordering_checker extends transaction_handler;
  `uvm_object_utils(ordering_checker)
  
  int expected_sequence_num = 0;
  
  function new(string name="ordering_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return 1;
  endfunction
  
  task handle(bus_transaction txn);
    `uvm_info("ORDER", $sformatf("Checking order: seq=%0d", txn.sequence_num), UVM_MEDIUM)
    if (txn.sequence_num != expected_sequence_num)
      `uvm_error("ORDER", $sformatf("Expected %0d got %0d", expected_sequence_num, txn.sequence_num));
    expected_sequence_num++;
  endtask
endclass

// Performance (Latency) Checker
class performance_checker extends transaction_handler;
  `uvm_object_utils(performance_checker)
  
  int max_latency_cycles = 1000;
  
  function new(string name="performance_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return txn.has_latency_info;
  endfunction
  
  task handle(bus_transaction txn);
    `uvm_info("PERF", $sformatf("Latency: %0d cycles", txn.latency), UVM_MEDIUM)
    if (txn.latency > max_latency_cycles)
      `uvm_warning("PERF", $sformatf("High latency: %0d > %0d", txn.latency, max_latency_cycles));
  endtask
endclass

// Assertion Checker (temporal properties)
class assertion_checker extends transaction_handler;
  `uvm_object_utils(assertion_checker)
  
  function new(string name="assertion_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return 1;
  endfunction
  
  task handle(bus_transaction txn);
    `uvm_info("ASSERT", "Checking temporal properties", UVM_MEDIUM)
    case (txn.command)
      WRITE: assert (txn.write_strobe != 0) else 
        `uvm_error("ASSERT", "Write with zero strobe")
      READ: assert (txn.addr[31:28] == 4'h0) else 
        `uvm_warning("ASSERT", "Read from unusual address range")
    endcase
  endtask
endclass

// ============================================================================
// Chain Builder
// ============================================================================
class checker_chain_builder;
  static function itransaction_handler build_standard_chain();
    protocol_checker prot;
    data_checker data;
    ordering_checker order;
    performance_checker perf;
    assertion_checker assert_chk;
    
    prot = protocol_checker::type_id::create("protocol");
    data = data_checker::type_id::create("data");
    order = ordering_checker::type_id::create("order");
    perf = performance_checker::type_id::create("perf");
    assert_chk = assertion_checker::type_id::create("assert");
    
    prot.set_successor(data);
    data.set_successor(order);
    order.set_successor(perf);
    perf.set_successor(assert_chk);
    
    return prot;
  endfunction
endclass

// ============================================================================
// Usage in Testbench - Verification Environment
// ============================================================================
class verification_env extends uvm_env;
  `uvm_component_utils(verification_env)
  
  itransaction_handler checker_chain;
  
  function new(string name = "verification_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    checker_chain = checker_chain_builder::build_standard_chain();
  endfunction
  
  task process_transaction(bus_transaction txn);
    checker_chain.process(txn);
  endtask
endclass

// ============================================================================
// Use Case 1: Write Filter
// ============================================================================
class write_filter extends transaction_handler;
  `uvm_object_utils(write_filter)
  
  function new(string name="write_filter");
    super.new(name);
  endfunction
  
  virtual function bit can_handle(bus_transaction txn);
    return (txn.command == WRITE);
  endfunction
  
  virtual task handle(bus_transaction txn);
    `uvm_info("FILTER", "Processing WRITE transaction", UVM_MEDIUM)
    if (successor != null) begin
      successor.process(txn);
    end
  endtask
endclass

// ============================================================================
// Use Case 2: Scoreboard Entry Handler
// ============================================================================
class scoreboard_entry extends transaction_handler;
  `uvm_object_utils(scoreboard_entry)
  
  logic [31:0] expected_data[$];
  
  function new(string name="scoreboard_entry");
    super.new(name);
  endfunction
  
  virtual function bit can_handle(bus_transaction txn);
    // Check if address is in expected range
    if (txn.addr >= 32'h1000_0000 && txn.addr <= 32'h2000_0000) begin
      return 1;
    end
    return 0;
  endfunction
  
  virtual task handle(bus_transaction txn);
    `uvm_info("SCOREBOARD", $sformatf("Storing expected data: 0x%h", txn.expected_value), UVM_MEDIUM)
    expected_data.push_back(txn.expected_value);
    if (successor != null) begin
      successor.process(txn);
    end
  endtask
endclass

// ============================================================================
// Use Case 3: State Transition Checker
// ============================================================================
class state_transition_checker extends transaction_handler;
  `uvm_object_utils(state_transition_checker)
  
  fsm_state_e current_state = IDLE;
  
  function new(string name="state_transition_checker");
    super.new(name);
  endfunction
  
  function bit can_handle(bus_transaction txn);
    return 1;
  endfunction
  
  virtual task handle(bus_transaction txn);
    fsm_state_e next_state = get_next_state(txn);
    if (!is_valid_transition(current_state, next_state)) begin
      `uvm_error("STATE", $sformatf("Invalid transition from %s to %s", 
        current_state.name(), next_state.name()));
    end else begin
      `uvm_info("STATE", $sformatf("Valid transition from %s to %s", 
        current_state.name(), next_state.name()), UVM_MEDIUM)
    end
    current_state = next_state;
    if (successor != null) begin
      successor.process(txn);
    end
  endtask
  
  virtual function fsm_state_e get_next_state(bus_transaction txn);
    fsm_state_e next = current_state;
    case (current_state)
      IDLE: if (txn.command == READ) next = READING;
            else if (txn.command == WRITE) next = WRITING;
      READING: next = WAITING;
      WRITING: next = WAITING;
      WAITING: next = IDLE;
    endcase
    return next;
  endfunction
  
  virtual function bit is_valid_transition(fsm_state_e current, fsm_state_e next);
    case ({current, next})
      {IDLE, IDLE}: return 0;
      {IDLE, READING}: return 1;
      {IDLE, WRITING}: return 1;
      {READING, WAITING}: return 1;
      {WRITING, WAITING}: return 1;
      {WAITING, IDLE}: return 1;
      default: return 0;
    endcase
  endfunction
endclass

  // ============================================================================
  // Test Block
  // ============================================================================
  initial begin
    verification_env env;
    bus_transaction txn;
    
    env = new("env");
    env.build_phase(null);
    
    // Create and process a WRITE transaction
    txn = bus_transaction::type_id::create("txn");
    txn.command = WRITE;
    txn.addr = 32'hABCD_1234;
    txn.data = 32'hDEAD_BEEF;
    txn.has_parity = 1;
    txn.parity = 8'h0;  // XOR of data bits
    txn.has_latency_info = 1;
    txn.latency = 500;
    txn.sequence_num = 0;
    txn.write_strobe = 4'b1111;
    txn.expected_value = 32'hDEAD_BEEF;
    
    $display("\n=== Processing WRITE Transaction ===");
    env.process_transaction(txn);
    
    // Create and process a READ transaction
    txn = bus_transaction::type_id::create("txn");
    txn.command = READ;
    txn.addr = 32'h0123_5678;
    txn.data = 32'h0;
    txn.has_parity = 0;
    txn.has_latency_info = 1;
    txn.latency = 1500;
    txn.sequence_num = 1;
    txn.expected_value = 32'hCAFE_BABE;
    
    $display("\n=== Processing READ Transaction ===");
    env.process_transaction(txn);
    
    $display("\n=== Test Complete ===\n");
    
  end

endmodule // test_chain_of_responsibility


/* 
# === Processing WRITE Transaction ===
# UVM_INFO .\chain_resp_example.sv(112) @ 0: reporter [PROTOCOL] Protocol check passed
# UVM_INFO .\chain_resp_example.sv(130) @ 0: reporter [DATA_CHK] Verifying data integrity
# UVM_INFO .\chain_resp_example.sv(153) @ 0: reporter [ORDER] Checking order: seq=0
# UVM_INFO .\chain_resp_example.sv(175) @ 0: reporter [PERF] Latency: 500 cycles
# UVM_INFO .\chain_resp_example.sv(194) @ 0: reporter [ASSERT] Checking temporal properties
# 
# === Processing READ Transaction ===
# UVM_INFO .\chain_resp_example.sv(112) @ 0: reporter [PROTOCOL] Protocol check passed
# UVM_INFO .\chain_resp_example.sv(153) @ 0: reporter [ORDER] Checking order: seq=1
# UVM_INFO .\chain_resp_example.sv(175) @ 0: reporter [PERF] Latency: 1500 cycles
# UVM_WARNING .\chain_resp_example.sv(177) @ 0: reporter [PERF] High latency: 1500 > 1000
# UVM_INFO .\chain_resp_example.sv(194) @ 0: reporter [ASSERT] Checking temporal properties
# 
# === Test Complete ===

*/
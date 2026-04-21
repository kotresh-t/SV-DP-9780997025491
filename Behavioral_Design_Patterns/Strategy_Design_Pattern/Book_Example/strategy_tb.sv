
//=============================================================================
// TOP MODULE & PLUSARG USAGE EXAMPLES
//=============================================================================
module tb_top;

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "../Book_Example_interface_class/write_transaction.sv"
`include "address_strategy.sv"
`include "core_strategies.sv"
`include "coverage_strategy.sv"

class demo_driver extends uvm_driver #(write_transaction);
  `uvm_component_utils(demo_driver)

  function new(string name = "demo_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    write_transaction req;

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(
        get_type_name(),
        $sformatf("Driving txn addr=0x%08h data=0x%08h", req.addr, req.data),
        UVM_MEDIUM
      )
      seq_item_port.item_done();
    end
  endtask
endclass

class strategy_demo_env extends uvm_env;
  `uvm_component_utils(strategy_demo_env)

  uvm_sequencer #(write_transaction) sequencer;
  demo_driver                    driver;

  function new(string name = "strategy_demo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer#(write_transaction)::type_id::create("sequencer", this);
    driver    = demo_driver::type_id::create("driver", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

// Usage in test:
class test_example extends uvm_test;
  `uvm_component_utils(test_example)

  strategy_demo_env env;

  function new(string name = "test_example", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = strategy_demo_env::type_id::create("env", this);
  endfunction

  task run_basic_sequence(string label, address_strategy strategy);
    flexible_write_sequence seq;

    seq = flexible_write_sequence::type_id::create($sformatf("%s_seq", label));
    seq.num_transactions = 5;
    seq.addr_strategy = strategy;

    `uvm_info(get_type_name(), $sformatf("Starting %s strategy demo", label), UVM_LOW)
    seq.start(env.sequencer);
  endtask

  task run_phase(uvm_phase phase);
    coverage_driven_write_sequence cov_seq;
    coverage_driven_address_strategy cov_strategy;

    phase.raise_objection(this);

    run_basic_sequence(
      "SEQUENTIAL",
      sequential_address_strategy::type_id::create("seq_strategy")
    );
    run_basic_sequence(
      "RANDOM",
      random_address_strategy::type_id::create("rand_strategy")
    );
    run_basic_sequence(
      "WEIGHTED",
      weighted_address_strategy::type_id::create("weighted_strategy")
    );

    cov_seq = coverage_driven_write_sequence::type_id::create("cov_seq");
    cov_seq.num_transactions = 8;
    cov_strategy = coverage_driven_address_strategy::type_id::create("cov_strategy");
    cov_seq.addr_strategy = cov_strategy;

    `uvm_info(get_type_name(), "Starting COVERAGE_DRIVEN strategy demo", UVM_LOW)
    cov_seq.start(env.sequencer);

    phase.drop_objection(this);
  endtask
endclass
/* 
//=============================================================================
// FLEXIBLE SEQUENCE WITH RUNTIME CONFIGURATION
//=============================================================================
class flexible_write_sequence extends uvm_sequence#(axi_txn);
  `uvm_object_utils(flexible_write_sequence)
  
  address_strategy addr_strategy;
  int num_transactions;
  string strategy_name;
  
  function new(string name = "flexible_write_sequence");
    super.new(name);
    num_transactions = 50;  // Default
  endfunction
  
  task body();
    axi_txn req;
    axi_txn_builder builder;
    
    `uvm_info(get_type_name(), $sformatf("Starting %0d txns with strategy: %s", 
                 num_transactions, strategy_name), UVM_LOW)
    
    for (int i = 0; i < num_transactions; i++) begin
      builder = new();
      req = builder.with_addr(addr_strategy.next_address())
                   .with_data($urandom())
                   .as_write()
                   .build();
      
      `uvm_info(get_type_name(), $sformatf("Txn #%0d: %s", i+1, req.convert2string()), UVM_MEDIUM)
      
      start_item(req);
      finish_item(req);
    end
  endtask
endclass

//=============================================================================
// CONFIG CLASS FOR PLUSARGS
//=============================================================================
class strategy_config extends uvm_object;
  `uvm_object_utils(strategy_config)
  
  string strategy_type = "random";  // Default
  int num_transactions = 50;
  bit enable_logging = 1;
  
  function new(string name = "strategy_config");
    super.new(name);
  endfunction
  
  function void parse_plusargs();
    if (!$value$plusargs("strategy=%s", strategy_type))
      `uvm_info("PLUSARGS", "No +strategy=... using default: random", UVM_LOW)
    
    if (!$value$plusargs("num_txns=%0d", num_transactions))
      `uvm_info("PLUSARGS", $sformatf("No +num_txns=... using default: %0d", num_transactions), UVM_LOW)
    
    if (!$value$plusargs("logging=%0d", enable_logging))
      `uvm_info("PLUSARGS", "No +logging=... using default: 1", UVM_LOW)
    
    `uvm_info("PLUSARGS", $sformatf("Config: strategy=%s, txns=%0d, logging=%0d", 
             strategy_type, num_transactions, enable_logging), UVM_LOW)
  endfunction
endclass

//=============================================================================
// ENHANCED TEST WITH RUNTIME STRATEGY SELECTION
//=============================================================================
class strategy_test extends uvm_test;
  `uvm_component_utils(strategy_test)
  
  strategy_config cfg;
  flexible_write_sequence seq;
  axi_env env;  // Assume existing environment
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create and parse configuration
    cfg = strategy_config::type_id::create("cfg");
    cfg.parse_plusargs();
    
    // Set config in environment
    uvm_config_db#(strategy_config)::set(this, "*", "strategy_cfg", cfg);
    
    // Build environment (existing)
    env = axi_env::type_id::create("env", this);
  endfunction
  
  task run_phase(uvm_phase phase);
    address_strategy strategy;
    
    phase.raise_objection(this);
    
    seq = flexible_write_sequence::type_id::create("seq");
    seq.num_transactions = cfg.num_transactions;
    
    // RUNTIME STRATEGY SELECTION via plusarg
    case (cfg.strategy_type)
      "sequential": begin
        strategy = sequential_address_strategy::type_id::create("seq_strategy");
        seq.strategy_name = "SEQUENTIAL";
      end
      
      "random": begin
        strategy = random_address_strategy::type_id::create("rand_strategy");
        seq.strategy_name = "RANDOM";
      end
      
      "weighted": begin
        strategy = weighted_address_strategy::type_id::create("weighted_strategy");
        seq.strategy_name = "WEIGHTED (70% hot spots)";
      end
      
      default: begin
        strategy = random_address_strategy::type_id::create("default_strategy");
        seq.strategy_name = "RANDOM (default)";
        `uvm_warning("STRATEGY", $sformatf("Unknown strategy '%s', using RANDOM", cfg.strategy_type))
      end
    endcase
    
    seq.addr_strategy = strategy;
    
    `uvm_info(get_type_name(), $sformatf("=== Executing %s Test ===", seq.strategy_name), UVM_LOW)
    
    seq.start(env.agent.sqr);
    
    phase.drop_objection(this);
  endtask
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "Strategy test completed successfully", UVM_LOW)
  endfunction
endclass

//=============================================================================
// MULTIPLE STRATEGY TEST (Bonus)
//=============================================================================
class multi_strategy_test extends uvm_test;
  `uvm_component_utils(multi_strategy_test)
  
  strategy_config cfg;
  flexible_write_sequence seq;
  axi_env env;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    address_strategy strategies[3];
    string strategy_names[3] = '{"SEQUENTIAL", "RANDOM", "WEIGHTED"}';
    
    phase.raise_objection(this);
    
    // Parse plusargs for total transactions per strategy
    int txns_per_strategy = 20;
    if (!$value$plusargs("txns_per_strategy=%0d", txns_per_strategy))
      txns_per_strategy = 20;
    
    foreach (strategies[i]) begin
      seq = flexible_write_sequence::type_id::create($sformatf("seq_%0d", i));
      seq.num_transactions = txns_per_strategy;
      seq.strategy_name = strategy_names[i];
      
      case (i)
        0: strategies[i] = sequential_address_strategy::type_id::create("seq");
        1: strategies[i] = random_address_strategy::type_id::create("rand");
        2: strategies[i] = weighted_address_strategy::type_id::create("weighted");
      endcase
      
      seq.addr_strategy = strategies[i];
      seq.start(env.agent.sqr);
    end
    
    phase.drop_objection(this);
  endtask
endclass


  logic clk;
  logic rst_n;
  axi4_if axi_if(clk, rst_n);
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
  end
  
  // Set interface
  initial begin
    uvm_config_db#(virtual axi4_if)::set(null, "*", "vif", axi_if);
  end
  */ 
  initial begin
    // PLUSARG USAGE EXAMPLES:
    // ./simv +strategy=sequential +num_txns=100 +logging=1
    // ./simv +strategy=weighted   +num_txns=50
    // ./simv +strategy=random     +num_txns=200
    // ./simv -test=multi_strategy_test +txns_per_strategy=30
    
    run_test("test_example");
  end
    
endmodule

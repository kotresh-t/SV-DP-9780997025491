class axi_test extends uvm_test;
  verification_env env;
  flexible_write_sequence seq;
  address_strategy addr_strategy; 

  `uvm_component_utils(axi_test)
 
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string strategy_type = "sequential";
    super.build_phase(phase);
   
    uvm_config_db#(string)::get(this, "", "strategy", strategy_type);

    env = verification_env::type_id::create("env", this);
    seq = flexible_write_sequence::type_id::create("seq");

    case (strategy_type)
        "sequential": addr_strategy = sequential_address_strategy::type_id::create("addr_strat", this);
        "random":     addr_strategy = random_address_strategy::type_id::create("addr_strat", this);
        "weighted":   addr_strategy = weighted_address_strategy::type_id::create("addr_strat", this);
        default:  addr_strategy = sequential_address_strategy::type_id::create("addr_strat", this);
    endcase
   

  endfunction

  task run_phase(uvm_phase phase);   
    phase.raise_objection(this);
        seq.set_strategy(addr_strategy); 
        seq.start(env.agent.sequencer);
        #1000; 
    phase.drop_objection(this);
  endtask

endclass
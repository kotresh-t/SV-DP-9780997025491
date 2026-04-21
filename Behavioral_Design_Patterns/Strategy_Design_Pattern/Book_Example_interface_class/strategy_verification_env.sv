class verification_env extends uvm_env;
  axi_agent agent;
  `uvm_component_utils(verification_env)

  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = axi_agent::type_id::create("agent", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", agent.driver.vif))
      `uvm_fatal("NOVIF", "Driver VIF not set")
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", agent.monitor.vif))
      `uvm_fatal("NOVIF", "Monitor VIF not set")
  endfunction
endclass
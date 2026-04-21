class pcie_tlp_agent extends uvm_agent;
  `uvm_component_utils(pcie_tlp_agent)  

  function new(string name="pcie_tlp_agent",uvm_component parent); 
   super.new(name,parent); 
  endfunction // new 
    
endclass // pcie_tlp_agent

class pcie_tlp_env extends uvm_env;
  `uvm_component_utils(pcie_tlp_env)

  pcie_tlp_agent tlp_agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tlp_agent = pcie_tlp_agent::type_id::create("tlp_agent", this);
  endfunction
endclass

class pcie_phy_agent extends uvm_agent;
  `uvm_component_utils(pcie_phy_agent)  

  function new(string name="pcie_phy_agent",uvm_component parent); 
   super.new(name,parent); 
  endfunction // new
  
endclass // pcie_phy_agent


class pcie_phy_env extends uvm_env;
  `uvm_component_utils(pcie_phy_env)

  pcie_phy_agent phy_agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    phy_agent = pcie_phy_agent::type_id::create("phy_agent", this);
  endfunction
endclass

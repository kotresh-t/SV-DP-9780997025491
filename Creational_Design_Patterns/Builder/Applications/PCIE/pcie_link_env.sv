class pcie_link_agent extends uvm_agent; 
    `uvm_object_utils(pcie_link_agent)

    function new(string name="pcie_link_agent",uvm_component parent=null); 
        super.new(name,parent); 
    endfunction // new 
endclass // pcie_link_agent


class pcie_link_env extends uvm_env;
  `uvm_component_utils(pcie_link_env)
  
  pcie_link_agent link_agent;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    link_agent = pcie_link_agent::type_id::create("link_agent", this);
  endfunction

//rc.link_agent.tx_ap.connect(ep.link_agent.rx_export);
//ep.link_agent.tx_ap.connect(rc.link_agent.rx_export);
endclass

class pcie_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(pcie_virtual_sequencer)

  /* 
  pcie_phy_sequencer  phy_sqr;
  pcie_link_sequencer link_sqr;
  pcie_tlp_sequencer  tlp_sqr;
  */ 
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

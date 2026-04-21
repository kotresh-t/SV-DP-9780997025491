class pcie_env extends uvm_env;
  `uvm_component_utils(pcie_env)

  pcie_phy_env  phy_env;
  pcie_link_env link_env;
  pcie_tlp_env  tlp_env;

  pcie_virtual_sequencer vseqr;
  pcie_env_builder      builder;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    builder = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    builder.build_phy(this);
    builder.build_link(this);
    builder.build_tlp(this);
    vseqr = pcie_virtual_sequencer::type_id::create("vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    builder.connect_layers(this);
  endfunction
endclass

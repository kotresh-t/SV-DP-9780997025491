// pcie_dllp_sequencer.sv
class pcie_dllp_sequencer extends uvm_sequencer #(pcie_dllp_item);
  `uvm_component_utils(pcie_dllp_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
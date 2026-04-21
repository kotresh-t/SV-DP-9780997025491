// pcie_tlp_sequencer.sv
class pcie_tlp_sequencer extends uvm_sequencer #(pcie_tlp_item);
`uvm_component_utils(pcie_tlp_sequencer)

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction
endclass
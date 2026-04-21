// pcie_dllp_monitor.sv
class pcie_dllp_monitor extends uvm_component;
`uvm_component_utils(pcie_dllp_monitor)

uvm_analysis_port #(pcie_dllp_item) ap;
uvm_analysis_imp #(pcie_dllp_item, pcie_dllp_monitor) phy_export; // From PHY/DUT

function new(string name, uvm_component parent);
  super.new(name, parent);
  ap = new("ap", this);
  phy_export = new("phy_export", this);
endfunction

function void write(pcie_dllp_item dllp);
  `uvm_info(get_full_name(), $sformatf("Observed DLLP: %s", dllp.convert2string()), UVM_MEDIUM)
  ap.write(dllp);
endfunction
endclass
// pcie_tlp_monitor.sv
class pcie_tlp_monitor extends uvm_component;
`uvm_component_utils(pcie_tlp_monitor)

virtual pcie_tlp_if vif;  // Or use TLM input port

uvm_analysis_port #(pcie_tlp_item) ap;

function new(string name, uvm_component parent);
  super.new(name, parent);
  ap = new("ap", this);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Optional: get interface
endfunction

task run_phase(uvm_phase phase);
  forever begin
    // Observe TLPs from lower layer (e.g., from link agent via export)
    // Or sample interface
    pcie_tlp_item tlp = observe_tlp();
    if (tlp != null) begin
      ap.write(tlp);
    end
  end
endtask

virtual function pcie_tlp_item observe_tlp();
  // In abstract model: this might be fed via TLM FIFO from link layer
  // For now, return null unless connected
  return null;
endfunction
endclass
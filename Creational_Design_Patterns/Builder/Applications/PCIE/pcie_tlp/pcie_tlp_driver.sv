// pcie_tlp_driver.sv
class pcie_tlp_driver extends uvm_driver #(pcie_tlp_item);
`uvm_component_utils(pcie_tlp_driver)

virtual pcie_tlp_if vif;  // Or use TLM/analysis port if abstract

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Optional: get virtual interface or use higher-level abstraction
  // if (!uvm_config_db#(virtual pcie_tlp_if)::get(this, "", "vif", vif))
  //   `uvm_fatal(get_full_name(), "No TLP interface provided")
endfunction

task run_phase(uvm_phase phase);
  forever begin
    seq_item_port.get_next_item(req);
    // Convert TLP item → flit/symbol stream (or send to lower layer via export)
    drive_tlp(req);
    seq_item_port.item_done();
  end
endtask

task drive_tlp(pcie_tlp_item tlp);
  // In abstract model: just emit via analysis port or TLM
  // In cycle-accurate: drive pins over multiple cycles
  `uvm_info(get_full_name(), $sformatf("Driving TLP: %s", tlp.convert2string()), UVM_HIGH)
  // Example: send to link layer via export (handled in env connection)
endtask
endclass
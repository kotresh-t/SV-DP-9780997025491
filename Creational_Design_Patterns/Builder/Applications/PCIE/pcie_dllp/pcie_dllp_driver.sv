// pcie_dllp_driver.sv
class pcie_dllp_driver extends uvm_driver #(pcie_dllp_item);
  `uvm_component_utils(pcie_dllp_driver)

  uvm_analysis_port #(pcie_dllp_item) tx_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    tx_ap = new("tx_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_full_name(), $sformatf("Driving DLLP: %s", req.convert2string()), UVM_MEDIUM)
      tx_ap.write(req);  // Send to lower layer (PHY or DUT)
      seq_item_port.item_done();
    end
  endtask
endclass
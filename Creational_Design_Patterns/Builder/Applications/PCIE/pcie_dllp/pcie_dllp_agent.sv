// pcie_dllp_agent.sv
class pcie_dllp_agent extends uvm_agent;
`uvm_component_utils(pcie_dllp_agent)

pcie_dllp_sequencer sequencer;
pcie_dllp_driver    driver;
pcie_dllp_monitor   monitor;

// Analysis ports for layer connectivity
uvm_analysis_port #(pcie_dllp_item) tx_ap;   // Outgoing to PHY
uvm_analysis_imp #(pcie_dllp_item, pcie_dllp_agent) rx_export; // Incoming from PHY

bit is_active = 1;

function new(string name, uvm_component parent);
  super.new(name, parent);
  tx_ap = new("tx_ap", this);
  rx_export = new("rx_export", this);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(bit)::get(this, "", "is_active", is_active))
    is_active = 1;

  if (is_active) begin
    sequencer = pcie_dllp_sequencer::type_id::create("sequencer", this);
    driver    = pcie_dllp_driver::type_id::create("driver", this);
  end
  monitor = pcie_dllp_monitor::type_id::create("monitor", this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (is_active) begin
    driver.seq_item_port.connect(sequencer.seq_item_export);
    driver.tx_ap.connect(tx_ap);
  end
  monitor.phy_export.connect(rx_export);
  
endfunction
endclass
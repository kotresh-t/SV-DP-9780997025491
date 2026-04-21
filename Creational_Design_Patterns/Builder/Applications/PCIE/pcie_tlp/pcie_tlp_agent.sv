// pcie_tlp_agent.sv
class pcie_tlp_agent extends uvm_agent;
`uvm_component_utils(pcie_tlp_agent)

// Components
pcie_tlp_sequencer  sequencer;
pcie_tlp_driver     driver;
pcie_tlp_monitor    monitor;

// Analysis ports
uvm_analysis_port #(pcie_tlp_item) tx_ap;  // Outgoing TLPs
uvm_analysis_port #(pcie_tlp_item) rx_ap;  // Incoming TLPs

// Configuration
bit is_active = 1;  // Default: active (can drive); set to 0 for passive

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get configuration
  if (!uvm_config_db#(bit)::get(this, "", "is_active", is_active)) begin
    `uvm_info(get_full_name(), "Using default is_active=1", UVM_LOW)
  end

  // Create sequencer & driver only if active
  if (is_active) begin
    sequencer = pcie_tlp_sequencer::type_id::create("sequencer", this);
    driver    = pcie_tlp_driver::type_id::create("driver", this);
  end

  // Monitor always present
  monitor = pcie_tlp_monitor::type_id::create("monitor", this);

  // Create analysis ports
  tx_ap = new("tx_ap", this);
  rx_ap = new("rx_ap", this);
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if (is_active) begin
    driver.seq_item_port.connect(sequencer.seq_item_export);
  end
  // Monitor broadcasts observed TLPs
  monitor.ap.connect(rx_ap);
  // Optional: if driver also emits what it sends
  // driver.tx_ap.connect(tx_ap);
endfunction

endclass
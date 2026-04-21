import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;

class traffic_monitor extends uvm_monitor;
  `uvm_component_utils(traffic_monitor)

  virtual traffic_if vif;
  uvm_analysis_port#(traffic_trans) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual traffic_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not set for traffic_monitor")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    traffic_trans tr;
    forever begin
      @(posedge vif.clk);
      tr = traffic_trans::type_id::create("tr");
      tr.n_lights = vif.n_lights;
      tr.s_lights = vif.s_lights;
      tr.e_lights = vif.e_lights;
      tr.w_lights = vif.w_lights;
      analysis_port.write(tr);
    end
  endtask

endclass
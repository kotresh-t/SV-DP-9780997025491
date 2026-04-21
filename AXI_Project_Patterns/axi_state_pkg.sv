`include "axi_if.sv"
`include "axi_pkg.sv"

package axi_state_pkg;
  import uvm_pkg::*;
  import axi_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {IDLE_ST, AW_PENDING_ST, W_PENDING_ST, B_WAITING_ST, ERROR_ST} axi_state_e;
  typedef class axi_aw_pending_state;

  virtual class axi_state;
    pure virtual function string get_name();
    pure virtual task handle_txn(axi_txn t, virtual axi_if vif);
    pure virtual function axi_state next_state(axi_txn t);
  endclass

  class axi_idle_state extends axi_state;
    virtual function string get_name();
      return "IDLE";
    endfunction

    virtual task handle_txn(axi_txn t, virtual axi_if vif);
      `uvm_info("STATE", "IDLE -> AW_PENDING", UVM_MEDIUM)
    endtask

    virtual function axi_state next_state(axi_txn t);
      axi_aw_pending_state st;
      st = new();
      return st;
    endfunction
  endclass

  class axi_aw_pending_state extends axi_state;
    virtual function string get_name();
      return "AW_PENDING";
    endfunction

    virtual task handle_txn(axi_txn t, virtual axi_if vif);
      vif.awaddr  <= t.addr;
      vif.awvalid <= 1'b1;
      do @(posedge vif.clk); while (!vif.awready);
      vif.awvalid <= 1'b0;
      `uvm_info("STATE", "AW sent", UVM_MEDIUM)
    endtask

    virtual function axi_state next_state(axi_txn t);
      axi_idle_state st;
      st = new();
      return st;
    endfunction
  endclass

  class axi_state_machine extends uvm_object;
    axi_state current_state;

    function new(string name = "axi_state_machine");
      super.new(name);
      begin
        axi_idle_state st;
        st = new();
        current_state = st;
      end
    endfunction

    task drive_txn(axi_txn t, virtual axi_if vif);
      current_state.handle_txn(t, vif);
      current_state = current_state.next_state(t);
    endtask
  endclass
endpackage

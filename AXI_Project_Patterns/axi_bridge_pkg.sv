`include "axi_if.sv"
`include "axi_pkg.sv"

`ifndef AXI_BRIDGE_PKG_SV
`define AXI_BRIDGE_PKG_SV
package axi_bridge_pkg;
  import uvm_pkg::*;
  import axi_pkg::*;
  `include "uvm_macros.svh"

  virtual class axi_protocol_impl extends uvm_object;
    function new(string name = "axi_protocol_impl");
      super.new(name);
    endfunction

    pure virtual task send_addr(axi_txn t, virtual axi_if vif);
    pure virtual task send_data(axi_txn t, virtual axi_if vif);
    pure virtual task recv_resp(axi_txn t, virtual axi_if vif);
  endclass

  class axi4_impl extends axi_protocol_impl;
    `uvm_object_utils(axi4_impl)

    function new(string name = "axi4_impl");
      super.new(name);
    endfunction

    virtual task send_addr(axi_txn t, virtual axi_if vif);
      vif.awaddr  <= t.addr;
      vif.awsize  <= 3'b010;
      vif.awlen   <= 8'd0;
      vif.awid    <= 4'd0;
      vif.awvalid <= 1'b1;
      do @(posedge vif.clk); while (!vif.awready);
      vif.awvalid <= 1'b0;
    endtask

    virtual task send_data(axi_txn t, virtual axi_if vif);
      vif.wdata  <= t.data;
      vif.wstrb  <= 4'hF;
      vif.wlast  <= 1'b1;
      vif.wvalid <= 1'b1;
      do @(posedge vif.clk); while (!vif.wready);
      vif.wvalid <= 1'b0;
      vif.wlast  <= 1'b0;
    endtask

    virtual task recv_resp(axi_txn t, virtual axi_if vif);
      vif.bready <= 1'b1;
      do @(posedge vif.clk); while (!vif.bvalid);
      t.resp = vif.bresp;
      vif.bready <= 1'b0;
    endtask
  endclass

  class axilite_impl extends axi4_impl;
    `uvm_object_utils(axilite_impl)

    function new(string name = "axilite_impl");
      super.new(name);
    endfunction

    virtual task send_addr(axi_txn t, virtual axi_if vif);
      vif.awaddr  <= t.addr;
      vif.awvalid <= 1'b1;
      do @(posedge vif.clk); while (!vif.awready);
      vif.awvalid <= 1'b0;
    endtask
  endclass
endpackage
`endif

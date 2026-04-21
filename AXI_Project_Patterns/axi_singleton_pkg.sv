`ifndef AXI_SINGLETON_PKG_SV
`define AXI_SINGLETON_PKG_SV
package axi_singleton_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class axi_cfg extends uvm_object;
    `uvm_object_utils(axi_cfg)

    static axi_cfg m_inst;
    string protocol = "AXILITE";

    function new(string name = "axi_cfg");
      super.new(name);
    endfunction

    static function axi_cfg get();
      if (m_inst == null) begin
        m_inst = axi_cfg::type_id::create("m_inst");
      end
      return m_inst;
    endfunction
  endclass
endpackage
`endif

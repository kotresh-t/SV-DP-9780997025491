`ifndef AXI_STRATEGY_PKG_SV
`define AXI_STRATEGY_PKG_SV
package axi_strategy_pkg;
  class axi_addr_strategy;
    virtual function bit [31:0] next_addr(bit [31:0] base, int unsigned idx);
      return base + (idx * 4);
    endfunction
  endclass

  class axi_stride_strategy extends axi_addr_strategy;
    int unsigned stride = 16;

    function new(int unsigned s = 16);
      stride = s;
    endfunction

    virtual function bit [31:0] next_addr(bit [31:0] base, int unsigned idx);
      return base + (idx * stride);
    endfunction
  endclass
endpackage
`endif

`include "axi_pkg.sv"

package axi_iterator_pkg;
  import axi_pkg::*;

  class axi_txn_iterator;
    axi_txn txns[];
    int idx = 0;

    function new(ref axi_txn t_array[]);
      txns = new[t_array.size()];
      foreach (t_array[i]) begin
        txns[i] = t_array[i];
      end
    endfunction

    function bit has_next();
      return (idx < txns.size());
    endfunction

    virtual function axi_txn next();
      if (has_next()) begin
        return txns[idx++];
      end
      return null;
    endfunction
  endclass

  class filtered_iterator extends axi_txn_iterator;
    bit [31:0] addr_mask;

    function new(ref axi_txn t_array[], bit [31:0] mask);
      super.new(t_array);
      addr_mask = mask;
    endfunction

    virtual function axi_txn next();
      axi_txn t;
      do begin
        t = super.next();
      end while (t != null && ((t.addr & addr_mask) != addr_mask));
      return t;
    endfunction
  endclass
endpackage

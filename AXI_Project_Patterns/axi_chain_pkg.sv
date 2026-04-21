`include "axi_pkg.sv"

package axi_chain_pkg;
  import uvm_pkg::*;
  import axi_pkg::*;
  `include "uvm_macros.svh"

  virtual class axi_checker;
    axi_checker next;

    pure virtual function bit can_handle(axi_txn t);
    pure virtual task check(axi_txn t, ref bit pass);
  endclass

  class syntax_checker extends axi_checker;
    virtual function bit can_handle(axi_txn t);
      return 1'b1;
    endfunction

    virtual task check(axi_txn t, ref bit pass);
      if (t.addr[1:0] != 2'b00) begin
        `uvm_error("SYNTAX", "Unaligned addr")
        pass = 1'b0;
      end
      if (next != null) begin
        next.check(t, pass);
      end
    endtask
  endclass

  class protocol_checker extends axi_checker;
    virtual function bit can_handle(axi_txn t);
      return (t.resp != 2'b00);
    endfunction

    virtual task check(axi_txn t, ref bit pass);
      if (t.resp == 2'b11) begin
        `uvm_error("PROTO", "SLVERR")
        pass = 1'b0;
      end
      if (next != null) begin
        next.check(t, pass);
      end
    endtask
  endclass

  class axi_observer #(type T = axi_txn);
    virtual task update(T t);
    endtask
  endclass

  class coverage_observer extends axi_observer #(axi_txn);
    int unsigned seen_low;
    int unsigned seen_high;
    int unsigned resp_ok;
    int unsigned resp_err;

    virtual task update(axi_txn t);
      if (t.addr <= 32'h0000_FFFF) begin
        seen_low++;
      end else begin
        seen_high++;
      end

      if (t.resp == 2'b00) begin
        resp_ok++;
      end else begin
        resp_err++;
      end
    endtask
  endclass
endpackage

package bridge_pkg;

  // ============================================================
  // Implementor interface
  // ============================================================
  virtual class bus_driver_if;
    pure virtual task write(bit [31:0] addr, bit [31:0] data);
    pure virtual task read (bit [31:0] addr, output bit [31:0] data);        
    pure virtual function string name();
  endclass

  // ============================================================
  // Concrete Implementors
  // ============================================================
  class apb_driver extends bus_driver_if;
    protected bit [31:0] mem[int unsigned];

    task write(bit [31:0] addr, bit [31:0] data);
      #2ns;
      mem[addr] = data;
      $display("[%0t] [APB] WRITE addr=0x%08h data=0x%08h", $time, addr, data);
    endtask

    task read(bit [31:0] addr, output bit [31:0] data);
      #2ns;
      if (mem.exists(addr)) data = mem[addr];
      else data = '0;
      $display("[%0t] [APB] READ  addr=0x%08h data=0x%08h", $time, addr, data);
    endtask

    function string name();
      return "APB_DRIVER";
    endfunction
  endclass

  class axi_lite_driver extends bus_driver_if;
    protected bit [31:0] mem[int unsigned];

    task write(bit [31:0] addr, bit [31:0] data);
      #1ns;
      mem[addr] = data;
      $display("[%0t] [AXI-L] WRITE addr=0x%08h data=0x%08h", $time, addr, data);
    endtask

    task read(bit [31:0] addr, output bit [31:0] data);
      #1ns;
      if (mem.exists(addr)) data = mem[addr];
      else data = '0;
      $display("[%0t] [AXI-L] READ  addr=0x%08h data=0x%08h", $time, addr, data);
    endtask

    function string name();
      return "AXI_LITE_DRIVER";
    endfunction
  endclass

  // ============================================================
  // Abstraction
  // ============================================================
  class reg_access;
    protected bus_driver_if impl;

    function new(bus_driver_if impl_h = null);
      impl = impl_h;
    endfunction

    function void set_implementor(bus_driver_if impl_h);
      impl = impl_h;
    endfunction

    function bus_driver_if get_implementor();
      return impl;
    endfunction

    function void check_impl();
      if (impl == null) begin
        $fatal(1, "[REG_ACCESS] Implementor handle is null");
      end
    endfunction

    virtual task reg_write(bit [31:0] addr, bit [31:0] data);
      check_impl();
      impl.write(addr, data);
    endtask

    virtual task reg_read(bit [31:0] addr, output bit [31:0] data);
      check_impl();
      impl.read(addr, data);
    endtask

    virtual task reg_update(bit [31:0] addr, bit [31:0] mask, bit [31:0] value);
      bit [31:0] cur;
      check_impl();
      reg_read(addr, cur);
      cur = (cur & ~mask) | (value & mask);
      reg_write(addr, cur);
    endtask
  endclass

  // ============================================================
  // Refined Abstraction #1
  // ============================================================
  class secure_reg_access extends reg_access;
    function new(bus_driver_if impl_h = null);
      super.new(impl_h);
    endfunction

    // Simple policy: only allow writes in secure window 0x0000_1000..0x0000_1FFF
    virtual task reg_write(bit [31:0] addr, bit [31:0] data);
      if ((addr < 32'h0000_1000) || (addr > 32'h0000_1FFF)) begin
        $display("[%0t] [SECURE] BLOCKED write addr=0x%08h data=0x%08h (impl=%s)",
                 $time, addr, data, get_implementor().name());
        return;
      end
      super.reg_write(addr, data);
    endtask
  endclass

  // ============================================================
  // Refined Abstraction #2
  // ============================================================
  class traced_reg_access extends reg_access;
    int unsigned txn_count;

    function new(bus_driver_if impl_h = null);
      super.new(impl_h);
      txn_count = 0;
    endfunction

    virtual task reg_write(bit [31:0] addr, bit [31:0] data);
      txn_count++;
      $display("[%0t] [TRACE] #%0d WRITE via %s", $time, txn_count, get_implementor().name());
      super.reg_write(addr, data);
    endtask

    virtual task reg_read(bit [31:0] addr, output bit [31:0] data);
      txn_count++;
      $display("[%0t] [TRACE] #%0d READ via %s", $time, txn_count, get_implementor().name());
      super.reg_read(addr, data);
    endtask
  endclass

endpackage : bridge_pkg

// ==============================================================
// Demo Testbench
// ==============================================================
module bridge_design_pattern_tb;
  import bridge_pkg::*;

  apb_driver       apb;
  axi_lite_driver  axi;
  reg_access       base_acc;
  secure_reg_access sec_acc;
  traced_reg_access trc_acc;
  bit [31:0] data_q;
  int pass_count = 0;
  int fail_count = 0;

  task automatic check_eq(string tc_name, bit [31:0] got, bit [31:0] exp);   
    if (got !== exp) begin
      fail_count++;
      $display("[FAIL] %s got=0x%08h exp=0x%08h", tc_name, got, exp);        
    end
    else begin
      pass_count++;
      $display("[PASS] %s value=0x%08h", tc_name, got);
    end
  endtask

  initial begin
    apb = new();
    axi = new();

    // 1) Same abstraction with APB implementor
    base_acc = new(apb);
    base_acc.reg_write(32'h0000_0010, 32'hDEAD_BEEF);
    base_acc.reg_read (32'h0000_0010, data_q);
    check_eq("TC1_APB_RW", data_q, 32'hDEAD_BEEF);

    // 2) Swap implementor at runtime: no abstraction rewrite
    base_acc.set_implementor(axi);
    base_acc.reg_write(32'h0000_0010, 32'h1234_5678);
    base_acc.reg_read (32'h0000_0010, data_q);
    check_eq("TC2_AXI_RW_AFTER_SWAP", data_q, 32'h1234_5678);

    // Verify APB and AXI memories are independent
    base_acc.set_implementor(apb);
    base_acc.reg_read(32'h0000_0010, data_q);
    check_eq("TC3_APB_STILL_OLD_VALUE", data_q, 32'hDEAD_BEEF);

    // 3) Refined abstraction (secure policy) on APB
    sec_acc = new(apb);
    sec_acc.reg_write(32'h0000_0008, 32'hAAAA_AAAA); // blocked
    sec_acc.reg_read (32'h0000_0008, data_q);
    check_eq("TC4_SECURE_BLOCKED_ADDR_UNCHANGED", data_q, 32'h0000_0000);    
    sec_acc.reg_write(32'h0000_1008, 32'h5555_5555); // allowed
    sec_acc.reg_read (32'h0000_1008, data_q);
    check_eq("TC5_SECURE_ALLOWED_ADDR_UPDATED", data_q, 32'h5555_5555);      

    // 4) Different refined abstraction (tracing) on AXI-Lite
    trc_acc = new(axi);
    trc_acc.reg_write(32'h0000_2000, 32'hABCD_EF01);
    trc_acc.reg_update(32'h0000_2000, 32'h0000_FF00, 32'h0000_1200);
    trc_acc.reg_read (32'h0000_2000, data_q);
    check_eq("TC6_TRACE_UPDATE_MASK_APPLIED", data_q, 32'hABCD_1201);        
    if (trc_acc.txn_count == 4) begin
      pass_count++;
      $display("[PASS] TC7_TRACE_TXN_COUNT count=%0d", trc_acc.txn_count);
    end
    else begin
      fail_count++;
      $display("[FAIL] TC7_TRACE_TXN_COUNT got=%0d exp=4", trc_acc.txn_count);
    end

    $display("\nBridge pattern demo completed. PASS=%0d FAIL=%0d\n", pass_count, fail_count);
    if (fail_count != 0) $fatal(1, "Bridge test failed");
    #5ns;
    $finish;
  end
endmodule
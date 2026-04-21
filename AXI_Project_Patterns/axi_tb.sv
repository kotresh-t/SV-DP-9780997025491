`include "axi_if.sv"
`include "axi_cmd_uvm_pkg.sv"
`include "axi_iterator_pkg.sv"
`include "axi_memento_pkg.sv"
`include "axi_state_pkg.sv"
`include "axi_chain_pkg.sv"

module axi_tb;
  import uvm_pkg::*;
  import axi_cmd_uvm_pkg::*;
  import axi_pkg::*;
  import axi_iterator_pkg::*;
  import axi_memento_pkg::*;
  import axi_state_pkg::*;
  import axi_chain_pkg::*;
  import axi_strategy_pkg::*;
  import axi_singleton_pkg::*;
  `include "uvm_macros.svh"

  bit clk;
  bit rstn;
  axi_if axi_if_inst(clk, rstn);

  axi_dut dut(.dut_if(axi_if_inst));

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial
  begin 
    rstn = 0;
    #20;
    rstn = 1;
  end 

  initial begin
    string protocol;

    protocol = "AXILITE";

    void'($value$plusargs("PROTOCOL=%s", protocol));
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_if_inst);
    uvm_config_db#(string)::set(null, "uvm_test_top.env.agt.drv", "protocol", protocol);

  end

  initial begin
    run_test("axi_dsl_test");
  end

class axi_dsl_test extends uvm_test;
  `uvm_component_utils(axi_dsl_test)

  axi_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    string dsl;
    axi_scenario_seq seq;
    axi_scenario_command cmds[$];

    phase.raise_objection(this);
// Start scenario only after reset is released.

    wait (axi_if_inst.rstn === 1'b1);
    repeat (2) @(posedge axi_if_inst.clk);

    dsl = "WRITE(0x100,0xDEADBEEF);WRITE(0x104,0xCAFEBABE)";
    void'($value$plusargs("SCENARIO=%s", dsl));

    seq = axi_scenario_seq::type_id::create("seq");
    axi_dsl_builder::build(dsl, cmds);
    seq.cmds = cmds;
    seq.start(env.agt.sqr);

    phase.drop_objection(this);
  endtask
endclass

class axi_stress_test extends uvm_test;
  `uvm_component_utils(axi_stress_test)

  axi_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_factory::get().set_type_override_by_type(
      axi_driver::get_type(), axi_stress_driver::get_type());
    env = axi_env::type_id::create("env", this);
  endfunction
endclass

class axi_bridge_axi4_test extends axi_dsl_test;
  `uvm_component_utils(axi_bridge_axi4_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    axi_cfg::get().protocol = "AXI4";
    uvm_config_db#(string)::set(this, "env.agt.drv", "protocol", "AXI4");
    super.build_phase(phase);
  endfunction
endclass

class axi_iterator_test extends uvm_test;
  `uvm_component_utils(axi_iterator_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_txn txns[];
    axi_txn t;
    axi_txn_iterator iter;
    filtered_iterator fiter;
    bit [31:0] filter_mask;
    int seen;
    int filtered_seen;

    phase.raise_objection(this);

    txns = new[4];
    foreach (txns[i]) begin
      txns[i] = axi_txn::type_id::create($sformatf("txn_%0d", i));
      txns[i].is_write = 1'b1;
    end
    txns[0].addr = 32'h0000_1000;
    txns[1].addr = 32'h0000_1004;
    txns[2].addr = 32'h0000_2000;
    txns[3].addr = 32'h0000_2008;

    iter = new(txns);
    seen = 0;
    while (iter.has_next()) begin
      t = iter.next();
      if (t != null) begin
        seen++;
      end
    end
    if (seen != 4) begin
      `uvm_error("ITER_TEST", $sformatf("Expected 4 items, saw %0d", seen))
    end

    filter_mask = 32'h0000_2000;
    fiter = new(txns, filter_mask);
    filtered_seen = 0;
    while (fiter.has_next()) begin
      t = fiter.next();
      if (t == null) begin
        break;
      end
      filtered_seen++;
      if ((t.addr & 32'h0000_2000) != 32'h0000_2000) begin
        `uvm_error("ITER_TEST", $sformatf("Filtered item failed mask: %08h", t.addr))
      end
    end
    if (filtered_seen != 2) begin
      `uvm_error("ITER_TEST", $sformatf("Expected 2 filtered items, saw %0d", filtered_seen))
    end

    phase.drop_objection(this);
  endtask
endclass

class axi_memento_test extends uvm_test;
  `uvm_component_utils(axi_memento_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_fsm_model model;
    axi_fsm_memento snap;

    phase.raise_objection(this);

    model = new("model");
    if (model.current_state != IDLE || model.cycle_count != 0) begin
      `uvm_error("MEMENTO_TEST", "Initial state mismatch")
    end

    model.step();
    model.step();
    snap = model.save();
    if (snap.state != W || snap.cycle_count != 2) begin
      `uvm_error("MEMENTO_TEST", "Snapshot mismatch")
    end

    model.step();
    model.step();
    if (model.current_state != IDLE || model.cycle_count != 4) begin
      `uvm_error("MEMENTO_TEST", "State advance mismatch")
    end

    model.restore(snap);
    if (model.current_state != W || model.cycle_count != 2) begin
      `uvm_error("MEMENTO_TEST", "Restore failed")
    end

    phase.drop_objection(this);
  endtask
endclass

class axi_strategy_singleton_test extends uvm_test;
  `uvm_component_utils(axi_strategy_singleton_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi_addr_strategy linear;
    axi_stride_strategy stride8;
    bit [31:0] a0;
    bit [31:0] a1;
    axi_cfg cfg_a;
    axi_cfg cfg_b;

    phase.raise_objection(this);

    linear = new();
    stride8 = new(8);
    a0 = linear.next_addr(32'h1000, 3);
    a1 = stride8.next_addr(32'h1000, 3);

    if (a0 != 32'h100C) begin
      `uvm_error("STRAT_TEST", $sformatf("Linear strategy mismatch: %08h", a0))
    end
    if (a1 != 32'h1018) begin
      `uvm_error("STRAT_TEST", $sformatf("Stride strategy mismatch: %08h", a1))
    end

    cfg_a = axi_cfg::get();
    cfg_a.protocol = "AXI4";
    cfg_b = axi_cfg::get();
    if (cfg_a != cfg_b) begin
      `uvm_error("SINGLETON_TEST", "Singleton returned different handles")
    end
    if (cfg_b.protocol != "AXI4") begin
      `uvm_error("SINGLETON_TEST", "Singleton state not shared")
    end

    phase.drop_objection(this);
  endtask
endclass

class axi_chain_test extends uvm_test;
  `uvm_component_utils(axi_chain_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    syntax_checker syntax;
    protocol_checker proto;
    axi_txn good;
    axi_txn resp_warn;
    coverage_observer cov;
    bit pass;

    phase.raise_objection(this);

    syntax = new();
    proto = new();
    syntax.next = proto;

    cov = new();

    good = axi_txn::type_id::create("good");
    good.addr = 32'h0000_1000;
    good.resp = 2'b00;
    cov.update(good);
    pass = 1'b1;
    syntax.check(good, pass);
    if (!pass) begin
      `uvm_error("CHAIN_TEST", "Good transaction failed")
    end

    resp_warn = axi_txn::type_id::create("resp_warn");
    resp_warn.addr = 32'h0001_0000;
    resp_warn.resp = 2'b10;
    cov.update(resp_warn);
    pass = 1'b1;
    syntax.check(resp_warn, pass);
    if (!pass) begin
      `uvm_error("CHAIN_TEST", "WARN response transaction unexpectedly failed")
    end

    if (cov.seen_low != 1 || cov.seen_high != 1 || cov.resp_ok != 1 || cov.resp_err != 1) begin
      `uvm_error("CHAIN_TEST", "Coverage observer counters mismatch")
    end

    phase.drop_objection(this);
  endtask
endclass

class axi_state_machine_test extends uvm_test;
  `uvm_component_utils(axi_state_machine_test)

  virtual axi_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("STATE_TEST", "No vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    axi_state_machine sm;
    axi_txn t;

    phase.raise_objection(this);
    wait (vif.rstn === 1'b1);

    sm = new("sm");
    t = axi_txn::type_id::create("t");
    t.addr = 32'h0000_1100;
    t.data = 32'h1234_5678;
    t.is_write = 1'b1;

    sm.drive_txn(t, vif);
    if (sm.current_state.get_name() != "AW_PENDING") begin
      `uvm_error("STATE_TEST", "Expected AW_PENDING after first drive")
    end

    sm.drive_txn(t, vif);
    if (sm.current_state.get_name() != "IDLE") begin
      `uvm_error("STATE_TEST", "Expected IDLE after second drive")
    end

    phase.drop_objection(this);
  endtask
endclass
endmodule

`timescale 1ns/1ps

interface cmd_if(input logic clk);
  logic rst_n;
  logic valid;
  logic write;
  logic [7:0]  addr;
  logic [31:0] data;
  logic ready;
endinterface

package cmd_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -----------------------------
  // Transaction
  // -----------------------------
  class cmd_item extends uvm_sequence_item;
    rand bit write;
    rand bit [7:0]  addr;
    rand bit [31:0] data;
         string tag;

    constraint c_addr { addr inside {[8'h00:8'h3F]}; }

    `uvm_object_utils_begin(cmd_item)
      `uvm_field_int(write, UVM_ALL_ON)
      `uvm_field_int(addr,  UVM_ALL_ON)
      `uvm_field_int(data,  UVM_ALL_ON)
      `uvm_field_string(tag, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cmd_item");
      super.new(name);
      tag = "UNSET";
    endfunction
  endclass

  // -----------------------------
  // Sequencer/Driver/Monitor/Agent
  // -----------------------------
  class cmd_sequencer extends uvm_sequencer#(cmd_item);
    `uvm_component_utils(cmd_sequencer)
    function new(string name = "cmd_sequencer", uvm_component parent = null);
      super.new(name, parent);
    endfunction
  endclass

  class cmd_driver extends uvm_driver#(cmd_item);
    `uvm_component_utils(cmd_driver)
    virtual cmd_if vif;

    function new(string name = "cmd_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual cmd_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("DRV", "cmd_if not found in config_db")
      end
    endfunction

    task run_phase(uvm_phase phase);
      cmd_item req;
      vif.valid <= 1'b0;
      vif.write <= 1'b0;
      vif.addr  <= '0;
      vif.data  <= '0;
      forever begin
        seq_item_port.get_next_item(req);
        @(posedge vif.clk);
        vif.valid <= 1'b1;
        vif.write <= req.write;
        vif.addr  <= req.addr;
        vif.data  <= req.data;
        @(posedge vif.clk);
        while (!vif.ready) @(posedge vif.clk);
        `uvm_info("DRV",
          $sformatf("Drove tag=%s wr=%0d addr=0x%0h data=0x%0h",
                    req.tag, req.write, req.addr, req.data), UVM_MEDIUM)
        vif.valid <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class cmd_monitor extends uvm_component;
    `uvm_component_utils(cmd_monitor)
    virtual cmd_if vif;
    uvm_analysis_port#(cmd_item) ap;

    function new(string name = "cmd_monitor", uvm_component parent = null);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual cmd_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("MON", "cmd_if not found in config_db")
      end
    endfunction

    task run_phase(uvm_phase phase);
      cmd_item t;
      forever begin
        @(posedge vif.clk);
        if (vif.valid && vif.ready) begin
          t = cmd_item::type_id::create("t");
          t.write = vif.write;
          t.addr  = vif.addr;
          t.data  = vif.data;
          t.tag   = "MON_CAPTURE";
          ap.write(t);
        end
      end
    endtask
  endclass

  class cmd_agent extends uvm_agent;
    `uvm_component_utils(cmd_agent)
    cmd_sequencer sqr;
    cmd_driver    drv;
    cmd_monitor   mon;
    virtual cmd_if vif;

    function new(string name = "cmd_agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual cmd_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("AGT", "cmd_if not found in config_db")
      end

      uvm_config_db#(virtual cmd_if)::set(this, "drv", "vif", vif);
      uvm_config_db#(virtual cmd_if)::set(this, "mon", "vif", vif);
      sqr = cmd_sequencer::type_id::create("sqr", this);
      drv = cmd_driver   ::type_id::create("drv", this);
      mon = cmd_monitor  ::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass

  class cmd_scoreboard extends uvm_component;
    `uvm_component_utils(cmd_scoreboard)
    uvm_analysis_imp#(cmd_item, cmd_scoreboard) imp;
    int unsigned seen;

    function new(string name = "cmd_scoreboard", uvm_component parent = null);
      super.new(name, parent);
      imp = new("imp", this);
      seen = 0;
    endfunction

    function void write(cmd_item t);
      seen++;
      `uvm_info("SCB",
        $sformatf("Observed #%0d wr=%0d addr=0x%0h data=0x%0h",
                  seen, t.write, t.addr, t.data), UVM_LOW)
    endfunction
  endclass

  class cmd_env extends uvm_env;
    `uvm_component_utils(cmd_env)
    cmd_agent agt;
    cmd_scoreboard scb;

    function new(string name = "cmd_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = cmd_agent     ::type_id::create("agt", this);
      scb = cmd_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agt.mon.ap.connect(scb.imp);
    endfunction
  endclass

  // -----------------------------
  // Atomic Sequences (actions)
  // -----------------------------
  class cfg_write_seq extends uvm_sequence#(cmd_item);
    `uvm_object_utils(cfg_write_seq)
    rand bit [7:0] cfg_addr;
    rand bit [31:0] cfg_data;

    function new(string name = "cfg_write_seq");
      super.new(name);
      cfg_addr = 8'h04;
      cfg_data = 32'hCAFE_0001;
    endfunction

    task body();
      cmd_item tx;
      tx = cmd_item::type_id::create("tx");
      start_item(tx);
      if (!tx.randomize() with {
        write == 1;
        addr  == local::cfg_addr;
        data  == local::cfg_data;
      }) `uvm_fatal("CFG_SEQ", "Randomize failed")
      tx.tag = "CFG";
      finish_item(tx);
    endtask
  endclass

  class burst_write_seq extends uvm_sequence#(cmd_item);
    `uvm_object_utils(burst_write_seq)
    rand int unsigned length;
    rand bit [7:0] base_addr;
    constraint c_len { length inside {[1:16]}; }

    function new(string name = "burst_write_seq");
      super.new(name);
      length = 4;
      base_addr = 8'h10;
    endfunction

    task body();
      cmd_item tx;
      for (int i = 0; i < length; i++) begin
        tx = cmd_item::type_id::create($sformatf("burst_tx_%0d", i));
        start_item(tx);
        if (!tx.randomize() with {
          write == 1;
          addr  == (local::base_addr + i);
        }) `uvm_fatal("BURST_SEQ", "Randomize failed")
        tx.tag = "BURST";
        finish_item(tx);
      end
    endtask
  endclass

  class readback_seq extends uvm_sequence#(cmd_item);
    `uvm_object_utils(readback_seq)
    rand int unsigned length;
    rand bit [7:0] base_addr;
    constraint c_len { length inside {[1:16]}; }

    function new(string name = "readback_seq");
      super.new(name);
      length = 4;
      base_addr = 8'h10;
    endfunction

    task body();
      cmd_item tx;
      for (int i = 0; i < length; i++) begin
        tx = cmd_item::type_id::create($sformatf("read_tx_%0d", i));
        start_item(tx);
        if (!tx.randomize() with {
          write == 0;
          addr  == (local::base_addr + i);
        }) `uvm_fatal("READ_SEQ", "Randomize failed")
        tx.tag = "READ";
        finish_item(tx);
      end
    endtask
  endclass

  // -----------------------------
  // Sequence Library (Scenario DSL building blocks)
  // -----------------------------
  class traffic_seq_lib extends uvm_sequence_library#(cmd_item);
    `uvm_object_utils(traffic_seq_lib)
    `uvm_sequence_library_utils(traffic_seq_lib)

    function new(string name = "traffic_seq_lib");
      super.new(name);
      init_sequence_library();
      add_typewide_sequence(cfg_write_seq ::get_type());
      add_typewide_sequence(burst_write_seq::get_type());
      add_typewide_sequence(readback_seq   ::get_type());
    endfunction
  endclass

  // -----------------------------
  // Command Pattern
  // -----------------------------
  virtual class scenario_command extends uvm_object;
    `uvm_object_utils(scenario_command)
    function new(string name = "scenario_command");
      super.new(name);
    endfunction
    pure virtual task execute(cmd_sequencer sqr);
  endclass

  class cfg_command extends scenario_command;
    `uvm_object_utils(cfg_command)
    bit [7:0] a;
    bit [31:0] d;
    function new(string name = "cfg_command");
      super.new(name);
      a = 8'h04;
      d = 32'h1;
    endfunction
    task execute(cmd_sequencer sqr);
      cfg_write_seq s = cfg_write_seq::type_id::create("cfg_seq");
      s.cfg_addr = a;
      s.cfg_data = d;
      s.start(sqr);
    endtask
  endclass

  class burst_command extends scenario_command;
    `uvm_object_utils(burst_command)
    int unsigned len;
    bit [7:0] base;
    function new(string name = "burst_command");
      super.new(name);
      len = 4;
      base = 8'h10;
    endfunction
    task execute(cmd_sequencer sqr);
      burst_write_seq s = burst_write_seq::type_id::create("burst_seq");
      s.length = len;
      s.base_addr = base;
      s.start(sqr);
    endtask
  endclass

  class read_command extends scenario_command;
    `uvm_object_utils(read_command)
    int unsigned len;
    bit [7:0] base;
    function new(string name = "read_command");
      super.new(name);
      len = 4;
      base = 8'h10;
    endfunction
    task execute(cmd_sequencer sqr);
      readback_seq s = readback_seq::type_id::create("read_seq");
      s.length = len;
      s.base_addr = base;
      s.start(sqr);
    endtask
  endclass

  // Scenario DSL parser:
  //  "CFG(04,CAFE0001);BURST(8,10);READ(8,10)"
  class scenario_dsl_builder extends uvm_object;
    `uvm_object_utils(scenario_dsl_builder)

    function new(string name = "scenario_dsl_builder");
      super.new(name);
    endfunction

    static function automatic int find_char(string s, byte ch);
      for (int i = 0; i < s.len(); i++) begin
        if (s.getc(i) == ch) return i;
      end
      return -1;
    endfunction

    static function automatic void split_tokens(string s, ref string toks[$]);
      string work;
      int p;
      toks.delete();
      work = s.toupper();
      while (work.len() > 0) begin
        p = find_char(work, 8'h3B);
        if (p == -1) begin
          toks.push_back(work.toupper());
          break;
        end
        if (p > 0) toks.push_back(work.substr(0, p-1));
        work = work.substr(p+1, work.len()-1);
      end
    endfunction

    static function automatic int unsigned parse_dec_or_hex(string s);
      int unsigned v;
      if (!$sscanf(s, "%h", v)) void'($sscanf(s, "%d", v));
      return v;
    endfunction

    static function automatic scenario_command parse_one(string tok);
      scenario_command c;
      int p0, p1;
      int pc;
      string name, args, a0, a1;
      int unsigned v0, v1;

      p0 = find_char(tok, 8'h28);
      p1 = find_char(tok, 8'h29);
      if ((p0 == -1) || (p1 == -1) || (p1 <= p0)) begin
        `uvm_fatal("DSL", $sformatf("Bad token: %s", tok))
      end
      name = tok.substr(0, p0-1);
      args = tok.substr(p0+1, p1-1);
      pc = find_char(args, 8'h2C);
      if ((pc <= 0) || (pc >= (args.len()-1))) begin
        `uvm_fatal("DSL", $sformatf("Args must be '<a>,<b>': %s", args))
      end
      a0 = args.substr(0, pc-1);
      a1 = args.substr(pc+1, args.len()-1);

      if ((name == "CFG")) begin
        cfg_command cc = cfg_command::type_id::create("cc");
        v0 = parse_dec_or_hex(a0);
        v1 = parse_dec_or_hex(a1);
        cc.a = v0[7:0];
        cc.d = v1;
        c = cc;
      end
      else if (name == "BURST") begin
        burst_command bc = burst_command::type_id::create("bc");
        v0 = parse_dec_or_hex(a0);
        v1 = parse_dec_or_hex(a1);
        bc.len = v0;
        bc.base = v1[7:0];
        c = bc;
      end
      else if (name == "READ") begin
        read_command rc = read_command::type_id::create("rc");
        v0 = parse_dec_or_hex(a0);
        v1 = parse_dec_or_hex(a1);
        rc.len = v0;
        rc.base = v1[7:0];
        c = rc;
      end
      else begin
        `uvm_fatal("DSL", $sformatf("Unknown command: %s", name))
      end
      return c;
    endfunction

    static function automatic void build(string dsl, ref scenario_command cmds[$]);
      string toks[$];
      cmds.delete();
      split_tokens(dsl, toks);
      foreach (toks[i]) begin
        if (toks[i].len() > 0) cmds.push_back(parse_one(toks[i]));
      end
    endfunction
  endclass

  class scenario_sequence extends uvm_sequence#(cmd_item);
    `uvm_object_utils(scenario_sequence)
    `uvm_declare_p_sequencer(cmd_sequencer)
    scenario_command cmds[$];

    function new(string name = "scenario_sequence");
      super.new(name);
    endfunction

    task body();
      foreach (cmds[i]) begin
        cmds[i].execute(p_sequencer);
      end
    endtask
  endclass

  // -----------------------------
  // Tests
  // -----------------------------
  class base_test extends uvm_test;
    `uvm_component_utils(base_test)
    cmd_env env;

    function new(string name = "base_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = cmd_env::type_id::create("env", this);
    endfunction
  endclass

  class dsl_test extends base_test;
    `uvm_component_utils(dsl_test)
    string dsl_string;

    function new(string name = "dsl_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
      scenario_sequence seq;
      scenario_command cmds[$];

      phase.raise_objection(this);
      if (!$value$plusargs("SCENARIO=%s", dsl_string)) begin
        dsl_string = "CFG(04,CAFE0001);BURST(8,10);READ(8,10)";
      end
      scenario_dsl_builder::build(dsl_string, cmds);

      seq = scenario_sequence::type_id::create("seq");
      foreach (cmds[i]) seq.cmds.push_back(cmds[i]);
      seq.start(env.agt.sqr);

      phase.drop_objection(this);
    endtask
  endclass

  class regression_test extends base_test;
    `uvm_component_utils(regression_test)
    int unsigned iterations;

    function new(string name = "regression_test", uvm_component parent = null);
      super.new(name, parent);
      iterations = 25;
    endfunction

    task run_phase(uvm_phase phase);
      traffic_seq_lib lib;
      phase.raise_objection(this);
      void'($value$plusargs("N_ITERS=%0d", iterations));

      lib = traffic_seq_lib::type_id::create("lib");
      lib.selection_mode = UVM_SEQ_LIB_RAND;
      lib.min_random_count = 1;
      lib.max_random_count = 5;

      repeat (iterations) begin
        lib.start(env.agt.sqr);
      end
      `uvm_info("REG",
        $sformatf("Completed regression iterations=%0d", iterations), UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass

endpackage

module dut_stub (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        valid,
  input  logic        write,
  input  logic [7:0]  addr,
  input  logic [31:0] data,
  output logic        ready
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ready <= 1'b0;
    else        ready <= 1'b1;
  end
endmodule

module tb_top;
  import uvm_pkg::*;
  import cmd_uvm_pkg::*;

  logic clk;
  cmd_if cmd_vif(clk);

  dut_stub u_dut (
    .clk   (clk),
    .rst_n (cmd_vif.rst_n),
    .valid (cmd_vif.valid),
    .write (cmd_vif.write),
    .addr  (cmd_vif.addr),
    .data  (cmd_vif.data),
    .ready (cmd_vif.ready)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    cmd_vif.rst_n = 1'b0;
    repeat (3) @(posedge clk);
    cmd_vif.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual cmd_if)::set(null, "uvm_test_top.env.agt", "vif", cmd_vif);
    // Example:
    // vsim ... +UVM_TESTNAME=dsl_test +SCENARIO=CFG(04,AA55AA55);BURST(4,20);READ(4,20)
    // vsim ... +UVM_TESTNAME=regression_test +N_ITERS=100
    run_test("dsl_test");
  end
endmodule

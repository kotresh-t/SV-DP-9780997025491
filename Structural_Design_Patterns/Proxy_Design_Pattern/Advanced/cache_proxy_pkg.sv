/*
  Proxy Design Pattern (Advanced UVM + RTL)
  =========================================

  Scenario:
    CPU issues memory transactions. A cache sits between the CPU and main memory.
    The cache is the Proxy that serves hits and forwards misses to main memory.

  Roles:
    - Subject: cache_if (memory access interface)
    - RealSubject: main memory inside the DUT
    - Proxy: cache inside the DUT
    - Client: CPU driver + sequence
*/

`include "uvm_macros.svh"
package cache_proxy_pkg;
  import uvm_pkg::*;

  // --------------------------------------------------------------------------
  // CPU transaction
  // --------------------------------------------------------------------------
  class cpu_mem_item extends uvm_sequence_item;
    rand bit         is_write;
    rand bit [31:0]  addr;
    rand bit [31:0]  data;

    `uvm_object_utils(cpu_mem_item)

    function new(string name = "cpu_mem_item");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("is_write=%0d addr=%h data=%h", is_write, addr, data);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Sequence: generate CPU traffic with locality
  // --------------------------------------------------------------------------
  class cpu_mem_seq extends uvm_sequence #(cpu_mem_item);
    `uvm_object_utils(cpu_mem_seq)

    int unsigned num_trans = 80;
    bit [31:0]   base_addr = 32'h1000_0000;
    int unsigned span_words = 64;   // 256 bytes
    int unsigned hot_words  = 16;   // 64 bytes

    function new(string name = "cpu_mem_seq");
      super.new(name);
    endfunction

    task body();
      cpu_mem_item req;

      for (int unsigned i = 0; i < num_trans; i++) begin
        req = cpu_mem_item::type_id::create($sformatf("req_%0d", i));
        start_item(req);

        req.is_write = ($urandom_range(0, 99) < 40);

        if ($urandom_range(0, 99) < 70) begin
          req.addr = base_addr + ($urandom_range(0, hot_words - 1) * 4);
        end else begin
          req.addr = base_addr + ($urandom_range(0, span_words - 1) * 4);
        end

        req.addr[1:0] = 2'b00;
        req.data = $urandom;

        finish_item(req);
      end
    endtask
  endclass

  // --------------------------------------------------------------------------
  // Driver: CPU client that drives the DUT via cache_if
  // --------------------------------------------------------------------------
  class cpu_driver extends uvm_driver #(cpu_mem_item);
    `uvm_component_utils(cpu_driver)

    virtual cache_if.tb vif;
    uvm_analysis_port #(cpu_mem_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual cache_if.tb)::get(this, "", "vif", vif)) begin
        `uvm_fatal("CPU_DRV", "vif not set for cpu_driver")
      end
    endfunction

    task wait_for_ready(int unsigned max_cycles = 20);
      int unsigned cycles;
      cycles = 0;
      while (!vif.req_ready) begin
        @(posedge vif.clk);
        cycles++;
        if (cycles > max_cycles) begin
          `uvm_fatal("CPU_DRV", "Timeout waiting for req_ready")
        end
      end
    endtask

    task wait_for_rsp(int unsigned max_cycles = 20);
      int unsigned cycles;
      cycles = 0;
      while (!vif.rsp_valid) begin
        @(posedge vif.clk);
        cycles++;
        if (cycles > max_cycles) begin
          `uvm_fatal("CPU_DRV", "Timeout waiting for rsp_valid")
        end
      end
    endtask

    task reset_dut();
      vif.req_valid = 1'b0;
      vif.req_write = 1'b0;
      vif.req_addr  = '0;
      vif.req_wdata = '0;
      vif.rst_n     = 1'b0;
      repeat (3) @(posedge vif.clk);
      vif.rst_n     = 1'b1;
      repeat (2) @(posedge vif.clk);
    endtask

    task run_phase(uvm_phase phase);
      cpu_mem_item req;
      cpu_mem_item rsp;

      reset_dut();

      forever begin
        seq_item_port.get_next_item(req);

        // Drive request away from posedge to avoid race with DUT
        @(negedge vif.clk);
        vif.req_valid = 1'b1;
        vif.req_write = req.is_write;
        vif.req_addr  = req.addr;
        vif.req_wdata = req.data;

        // Wait for ready (always 1 in DUT, but keep it general)
        wait_for_ready();

        @(negedge vif.clk);
        vif.req_valid = 1'b0;

        // Wait for response
        wait_for_rsp();

        if (!req.is_write) begin
          req.data = vif.rsp_rdata;
        end

        rsp = cpu_mem_item::type_id::create("rsp");
        rsp.is_write = req.is_write;
        rsp.addr     = req.addr;
        rsp.data     = req.data;
        ap.write(rsp);

        seq_item_port.item_done();
      end
    endtask
  endclass

  // --------------------------------------------------------------------------
  // Sequencer
  // --------------------------------------------------------------------------
  class cpu_sequencer extends uvm_sequencer #(cpu_mem_item);
    `uvm_component_utils(cpu_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Agent
  // --------------------------------------------------------------------------
  class cpu_agent extends uvm_component;
    `uvm_component_utils(cpu_agent)

    cpu_driver    driver;
    cpu_sequencer sequencer;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      driver    = cpu_driver::type_id::create("driver", this);
      sequencer = cpu_sequencer::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Scoreboard: reference memory and basic checks
  // --------------------------------------------------------------------------
  class cpu_scoreboard extends uvm_component;
    `uvm_component_utils(cpu_scoreboard)

    uvm_analysis_imp #(cpu_mem_item, cpu_scoreboard) ap;

    bit [31:0] ref_mem[bit [31:0]];

    int unsigned num_reads;
    int unsigned num_writes;
    int unsigned num_errors;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void write(cpu_mem_item t);
      bit [31:0] exp;

      if (t.is_write) begin
        ref_mem[t.addr] = t.data;
        num_writes++;
      end else begin
        if (!ref_mem.exists(t.addr)) begin
          ref_mem[t.addr] = '0;
        end
        exp = ref_mem[t.addr];
        num_reads++;
        if (t.data !== exp) begin
          num_errors++;
          `uvm_error("SCOREBOARD", $sformatf("Read mismatch: addr=%h exp=%h got=%h", t.addr, exp, t.data))
        end
      end
    endfunction

    function void report_phase(uvm_phase phase);
      $display("SCOREBOARD: reads=%0d writes=%0d errors=%0d", num_reads, num_writes, num_errors);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Environment
  // --------------------------------------------------------------------------
  class cache_proxy_env extends uvm_env;
    `uvm_component_utils(cache_proxy_env)

    cpu_agent      agent;
    cpu_scoreboard sb;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = cpu_agent::type_id::create("agent", this);
      sb    = cpu_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.ap.connect(sb.ap);
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // Test
  // --------------------------------------------------------------------------
  class cache_proxy_test extends uvm_test;
    `uvm_component_utils(cache_proxy_test)

    cache_proxy_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = cache_proxy_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      cpu_mem_seq seq;

      phase.raise_objection(this);
      seq = cpu_mem_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      phase.drop_objection(this);
    endtask
  endclass

endpackage

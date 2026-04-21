`include "axi_if.sv"
`include "axi_pkg.sv"
`include "axi_bridge_pkg.sv"
`include "axi_strategy_pkg.sv"
`include "axi_singleton_pkg.sv"

`ifndef AXI_CMD_UVM_PKG_SV
`define AXI_CMD_UVM_PKG_SV
package axi_cmd_uvm_pkg;
  import uvm_pkg::*;
  import axi_pkg::*;
  import axi_bridge_pkg::*;
  import axi_strategy_pkg::*;
  import axi_singleton_pkg::*;
  `include "uvm_macros.svh"

  typedef virtual axi_if vif_t;

  class axi_cmd_item extends uvm_sequence_item;
    axi_txn payload;
    string tag;

    `uvm_object_utils_begin(axi_cmd_item)
      `uvm_field_object(payload, UVM_ALL_ON)
      `uvm_field_string(tag, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_cmd_item");
      super.new(name);
      payload = axi_txn::type_id::create("payload");
    endfunction
  endclass

  class axi_sequencer extends uvm_sequencer #(axi_cmd_item);
    `uvm_component_utils(axi_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class axi_driver extends uvm_driver #(axi_cmd_item);
    `uvm_component_utils(axi_driver)

    vif_t vif;
    axi_protocol_impl impl;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      string protocol;

      super.build_phase(phase);
      if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif)) begin
        `uvm_fatal("DRV", "No vif")
      end

      if (!uvm_config_db#(string)::get(this, "", "protocol", protocol)) begin
        protocol = axi_cfg::get().protocol;
      end

      case (protocol)
        "AXI4":    impl = axi4_impl::type_id::create("impl");
        "AXILITE": impl = axilite_impl::type_id::create("impl");
        default:   `uvm_fatal("DRV", $sformatf("Unknown protocol: %s", protocol))
      endcase
    endfunction

    task run_phase(uvm_phase phase);
      axi_cmd_item req;

      // Drive known idle values before starting transactions.
      vif.awvalid <= 1'b0;
      vif.wvalid  <= 1'b0;
      vif.wlast   <= 1'b0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b0;
      vif.rready  <= 1'b0;

      forever begin
        seq_item_port.get_next_item(req);
        wait (vif.rstn === 1'b1);
        if (req.payload.is_write) begin
          impl.send_addr(req.payload, vif);
          impl.send_data(req.payload, vif);
          impl.recv_resp(req.payload, vif);
        end
        `uvm_info("DRV", $sformatf("Drove %s", req.tag), UVM_MEDIUM)
        seq_item_port.item_done();
      end
    endtask
  endclass

  class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    vif_t vif;
    uvm_analysis_port #(axi_cmd_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif)) begin
        `uvm_fatal("MON", "No vif")
      end
    endfunction

    task run_phase(uvm_phase phase);
      axi_cmd_item t;

      forever begin
        @(posedge vif.clk);
        if (vif.awvalid && vif.awready) begin
          t = axi_cmd_item::type_id::create("t");
          t.payload.addr = vif.awaddr;
          t.payload.is_write = 1'b1;
          t.tag = "MON_AW";
          ap.write(t);
        end
      end
    endtask
  endclass

  class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_sequencer sqr;
    axi_driver drv;
    axi_monitor mon;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = axi_monitor::type_id::create("mon", this);
      if (is_active == UVM_ACTIVE) begin
        sqr = axi_sequencer::type_id::create("sqr", this);
        drv = axi_driver::type_id::create("drv", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(sqr.seq_item_export);
      end
    endfunction
  endclass

  class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    axi_agent agt;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = axi_agent::type_id::create("agt", this);
    endfunction
  endclass

  virtual class axi_scenario_command extends uvm_object;
    `uvm_object_utils(axi_scenario_command)

    function new(string name = "axi_scenario_command");
      super.new(name);
    endfunction

    pure virtual task execute(axi_sequencer sqr);
  endclass

  class axi_one_item_seq extends uvm_sequence #(axi_cmd_item);
    `uvm_object_utils(axi_one_item_seq)

    axi_cmd_item req;

    function new(string name = "axi_one_item_seq");
      super.new(name);
    endfunction

    task body();
      if (req == null) begin
        `uvm_fatal("SEQ", "req is null")
      end
      start_item(req);
      finish_item(req);
    endtask
  endclass

  class axi_write_cmd extends axi_scenario_command;
    `uvm_object_utils(axi_write_cmd)

    bit [31:0] addr;
    bit [31:0] data;

    function new(string name = "axi_write_cmd");
      super.new(name);
    endfunction

    task execute(axi_sequencer sqr);
      axi_cmd_item item;
      axi_one_item_seq seq;
      axi_txn_builder bld;

      item = axi_cmd_item::type_id::create("item");
      bld = new();
      item.payload = bld.with_write().with_addr(addr).with_data(data).build();
      item.tag = "WRITE";

      seq = axi_one_item_seq::type_id::create("seq");
      seq.req = item;
      seq.start(sqr);
    endtask
  endclass

  class axi_dsl_builder;
    static function automatic int find_char(string s, byte ch);
      for (int i = 0; i < s.len(); i++) begin
        if (s.getc(i) == ch) begin
          return i;
        end
      end
      return -1;
    endfunction

    static function automatic void split_tokens(string s, ref string toks[$]);
      string work;
      int p;

      work = s.toupper();
      toks.delete();
      while (work.len() > 0) begin
        p = find_char(work, 8'h3B);
        if (p == -1) begin
          toks.push_back(work);
          break;
        end

        if (p > 0) begin
          toks.push_back(work.substr(0, p - 1));
        end

        if (p + 1 >= work.len()) begin
          break;
        end
        work = work.substr(p + 1, work.len() - 1);
      end
    endfunction

    static function automatic axi_write_cmd parse_one(string tok);
      axi_write_cmd cmd;
      int unsigned addr;
      int unsigned data;

      if ($sscanf(tok, "WRITE(%h,%h)", addr, data) == 2) begin
        cmd = axi_write_cmd::type_id::create("cmd");
        cmd.addr = addr;
        cmd.data = data;
        return cmd;
      end
      return null;
    endfunction

    static function automatic void build(string dsl, ref axi_scenario_command cmds[$]);
      string toks[$];
      axi_write_cmd cmd;

      split_tokens(dsl, toks);
      foreach (toks[i]) begin
        cmd = parse_one(toks[i]);
        if (cmd != null) begin
          cmds.push_back(cmd);
        end
      end
    endfunction
  endclass

  class axi_scenario_seq extends uvm_sequence #(axi_cmd_item);
    `uvm_object_utils(axi_scenario_seq)
    `uvm_declare_p_sequencer(axi_sequencer)

    axi_scenario_command cmds[$];

    function new(string name = "axi_scenario_seq");
      super.new(name);
    endfunction

    task body();
      foreach (cmds[i]) begin
        cmds[i].execute(p_sequencer);
      end
    endtask
  endclass

  class axi_stress_driver extends axi_driver;
    `uvm_component_utils(axi_stress_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass
endpackage
`endif

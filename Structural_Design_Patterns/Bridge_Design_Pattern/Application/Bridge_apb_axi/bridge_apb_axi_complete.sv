// ===== UVM Imports =====
`include "uvm_macros.svh"
import uvm_pkg::*;

// ===== Interfaces =====
interface axi4_if(input bit clk, input bit rst_n);
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;
  logic [31:0] wdata;
  logic        wvalid;
  logic        wready;
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;
endinterface

interface apb_if(input bit clk, input bit rst_n);
  logic [31:0] paddr;
  logic        pvalid;
  logic        pready;
  logic [31:0] pdata;
  logic [31:0] prdata;
  logic        pwrite;
endinterface

// ===== Generic Transaction =====
class generic_txn extends uvm_sequence_item;
  rand bit[31:0] addr;
  rand bit[31:0] data;
  bit[31:0]      response;
  
  `uvm_object_utils_begin(generic_txn)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(response, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "generic_txn");
    super.new(name);
  endfunction
  
  constraint addr_range { addr inside {[32'h0000_0000 : 32'h0000_FFFF]}; }
  constraint data_range { data inside {[32'h0000_0000 : 32'hFFFF_FFFF]}; }
endclass

// ===== Abstract Implementor =====
virtual class protocol_driver_impl;
  pure virtual task send_addr_phase(bit[31:0] addr);
  pure virtual task send_data_phase(bit[31:0] data);
  pure virtual task receive_response(output bit[31:0] resp);
endclass

// ===== AXI4 Implementation =====
class axi4_driver_impl extends protocol_driver_impl;
  virtual axi4_if vif;

  function new(virtual axi4_if vif);
    this.vif = vif;
  endfunction

  virtual task send_addr_phase(bit[31:0] addr);
    vif.awaddr = addr;
    vif.awvalid = 1;
    @(posedge vif.clk);
    while (!vif.awready)
      @(posedge vif.clk);
    vif.awvalid = 0;
  endtask

  virtual task send_data_phase(bit[31:0] data);
    vif.wdata = data;
    vif.wvalid = 1;
    @(posedge vif.clk);
    while (!vif.wready)
      @(posedge vif.clk);
    vif.wvalid = 0;
  endtask

  virtual task receive_response(output bit[31:0] resp);
    @(posedge vif.bvalid);
    resp = vif.bresp;
  endtask
endclass

// ===== APB Implementation =====
class apb_driver_impl extends protocol_driver_impl;
  virtual apb_if vif;

  function new(virtual apb_if vif);
    this.vif = vif;
  endfunction

  virtual task send_addr_phase(bit[31:0] addr);
    vif.paddr = addr;
    vif.pvalid = 1;
    @(posedge vif.clk);
  endtask

  virtual task send_data_phase(bit[31:0] data);
    vif.pdata = data;
    @(posedge vif.clk);
    while (!vif.pready)
      @(posedge vif.clk);
    vif.pvalid = 0;
  endtask

  virtual task receive_response(output bit[31:0] resp);
    resp = vif.prdata;
  endtask
endclass

// ===== Sequencer =====
class sequencer extends uvm_sequencer #(generic_txn);
  `uvm_component_utils(sequencer)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

// ===== Driver =====
class driver extends uvm_driver #(generic_txn);
  `uvm_component_utils(driver)
  
  virtual axi4_if axi4_vif;
  virtual apb_if  apb_vif;
  string          protocol;
  protocol_driver_impl impl;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db #(string)::get(this, "", "protocol", protocol))
      protocol = "AXI4";
    
    `uvm_info("driver", $sformatf("Using protocol: %s", protocol), UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    axi4_driver_impl axi4_impl;
    apb_driver_impl apb_impl;
    
    super.connect_phase(phase);
    
    case (protocol)
      "AXI4": begin
        if (!uvm_config_db #(virtual axi4_if)::get(this, "", "axi4_vif", axi4_vif))
          `uvm_fatal("driver", "Failed to get axi4_vif");
        axi4_impl = new(axi4_vif);
        impl = axi4_impl;
      end
      "APB": begin
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
          `uvm_fatal("driver", "Failed to get apb_vif");
        apb_impl = new(apb_vif);
        impl = apb_impl;
      end
      default: `uvm_fatal("driver", $sformatf("Unknown protocol: %s", protocol));
    endcase
  endfunction

  task run_phase(uvm_phase phase);
    generic_txn txn;
    bit[31:0] resp;
    
    phase.raise_objection(this);
    
    repeat(3) begin
      get_next_item(txn);
      `uvm_info("driver", $sformatf("Sending Txn: addr=0x%0h, data=0x%0h", txn.addr, txn.data), UVM_LOW)
      
      impl.send_addr_phase(txn.addr);
      impl.send_data_phase(txn.data);
      impl.receive_response(resp);
      
      txn.response = resp;
      `uvm_info("driver", $sformatf("Response: 0x%0h", resp), UVM_LOW)
      
      item_done();
    end
    
    phase.drop_objection(this);
  endtask
endclass

// ===== Sequence =====
class base_sequence extends uvm_sequence #(generic_txn);
  `uvm_object_utils(base_sequence)
  
  function new(string name = "base_sequence");
    super.new(name);
  endfunction
  
  task body();
    generic_txn txn;
    repeat(3) begin
      txn = generic_txn::type_id::create("txn");
      start_item(txn);
      assert (txn.randomize());
      finish_item(txn);
    end
  endtask
endclass

// ===== Environment =====
class env extends uvm_env;
  `uvm_component_utils(env)
  
  sequencer sqr;
  driver    drv;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = sequencer::type_id::create("sqr", this);
    drv = driver::type_id::create("drv", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

// ===== Test Base =====
class test_base extends uvm_test;
  `uvm_component_utils(test_base)
  
  env test_env;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    test_env = env::type_id::create("test_env", this);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
endclass

// ===== AXI4 Test =====
class axi4_test extends test_base;
  `uvm_component_utils(axi4_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(string)::set(this, "test_env.drv", "protocol", "AXI4");
  endfunction
  
  task run_phase(uvm_phase phase);
    base_sequence seq;
    seq = base_sequence::type_id::create("seq");
    seq.start(test_env.sqr);
  endtask
endclass

// ===== APB Test =====
class apb_test extends test_base;
  `uvm_component_utils(apb_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(string)::set(this, "test_env.drv", "protocol", "APB");
  endfunction
  
  task run_phase(uvm_phase phase);
    base_sequence seq;
    seq = base_sequence::type_id::create("seq");
    seq.start(test_env.sqr);
  endtask
endclass

// ===== AXI4 Slave =====
module axi4_slave(axi4_if axi_vif);
  always @(posedge axi_vif.clk) begin
    if (!axi_vif.rst_n) begin
      axi_vif.awready <= 0;
      axi_vif.wready <= 0;
      axi_vif.bvalid <= 0;
    end else begin
      axi_vif.awready <= axi_vif.awvalid;
      axi_vif.wready <= axi_vif.wvalid;
      axi_vif.bvalid <= axi_vif.wready;
    end
  end
endmodule

// ===== APB Slave =====
module apb_slave(apb_if apb_vif);
  always @(posedge apb_vif.clk) begin
    if (!apb_vif.rst_n) begin
      apb_vif.pready <= 0;
      apb_vif.prdata <= 0;
    end else begin
      apb_vif.pready <= apb_vif.pvalid;
      apb_vif.prdata <= apb_vif.pdata;
    end
  end
endmodule

// ===== Testbench =====
module tb_bridge_apb_axi;
  reg clk;
  reg rst_n;
  
  axi4_if axi_vif(clk, rst_n);
  apb_if  apb_vif(clk, rst_n);
  
  axi4_slave axi_slave_inst(.axi_vif(axi_vif));
  apb_slave  apb_slave_inst(.apb_vif(apb_vif));
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 0;
    repeat(2) @(posedge clk);
    rst_n = 1;
  end
  
  initial begin
    uvm_config_db #(virtual axi4_if)::set(null, "uvm_test_top.test_env.drv", "axi4_vif", axi_vif);
    uvm_config_db #(virtual apb_if)::set(null, "uvm_test_top.test_env.drv", "apb_vif", apb_vif);
    run_test();
  end
  
  initial begin
    #500us $finish;
  end
endmodule

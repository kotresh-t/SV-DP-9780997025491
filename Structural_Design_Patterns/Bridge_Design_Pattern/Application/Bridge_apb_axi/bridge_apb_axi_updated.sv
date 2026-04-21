// ===== Bridge Design Pattern - APB <-> AXI4 =====
// Demonstrates the Bridge pattern where Abstraction (driver) is decoupled from Implementation (AXI4/APB specific code)

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

// ===== Abstract Implementor =====
virtual class protocol_impl;
  pure virtual task send_addr_phase(bit[31:0] addr);
  pure virtual task send_data_phase(bit[31:0] data);
  pure virtual task receive_response(output bit[31:0] resp);
endclass

// ===== AXI4 Concrete Implementor =====
class axi4_impl extends protocol_impl;
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
    `uvm_info("AXI4_IMPL", $sformatf("Address sent: 0x%0h", addr), UVM_LOW)
  endtask

  virtual task send_data_phase(bit[31:0] data);
    vif.wdata = data;
    vif.wvalid = 1;
    @(posedge vif.clk);
    while (!vif.wready)
      @(posedge vif.clk);
    vif.wvalid = 0;
    `uvm_info("AXI4_IMPL", $sformatf("Data sent: 0x%0h", data), UVM_LOW)
  endtask

  virtual task receive_response(output bit[31:0] resp);
    @(posedge vif.bvalid);
    resp = vif.bresp;
    `uvm_info("AXI4_IMPL", $sformatf("Response received: 0x%0h", resp), UVM_LOW)
  endtask
endclass

// ===== APB Concrete Implementor =====
class apb_impl extends protocol_impl;
  virtual apb_if vif;

  function new(virtual apb_if vif);
    this.vif = vif;
  endfunction

  virtual task send_addr_phase(bit[31:0] addr);
    vif.paddr = addr;
    vif.pvalid = 1;
    @(posedge vif.clk);
    `uvm_info("APB_IMPL", $sformatf("Address sent: 0x%0h", addr), UVM_LOW)
  endtask

  virtual task send_data_phase(bit[31:0] data);
    vif.pdata = data;
    @(posedge vif.clk);
    while (!vif.pready)
      @(posedge vif.clk);
    vif.pvalid = 0;
    `uvm_info("APB_IMPL", $sformatf("Data sent: 0x%0h", data), UVM_LOW)
  endtask

  virtual task receive_response(output bit[31:0] resp);
    resp = vif.prdata;
    `uvm_info("APB_IMPL", $sformatf("Response received: 0x%0h", resp), UVM_LOW)
  endtask
endclass

// ===== Abstraction (Bridge) =====
class driver extends uvm_component;
  `uvm_component_utils(driver)
  
  virtual axi4_if axi4_vif;
  virtual apb_if  apb_vif;
  string          protocol_name;
  protocol_impl   impl;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(string)::get(this, "", "protocol", protocol_name))
      protocol_name = "AXI4";
    `uvm_info("DRIVER", $sformatf("Selected protocol: %s", protocol_name), UVM_MEDIUM)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    impl_select();
  endfunction

  function void impl_select();
    axi4_impl axi4_tmp;
    apb_impl apb_tmp;
    
    if (protocol_name == "AXI4") begin
      if (!uvm_config_db #(virtual axi4_if)::get(this, "", "axi4_vif", axi4_vif))
        `uvm_fatal("DRIVER", "Failed to get axi4_vif");
      axi4_tmp = new(axi4_vif);
      impl = axi4_tmp;
      `uvm_info("DRIVER", "AXI4 implementation selected", UVM_LOW)
    end else if (protocol_name == "APB") begin
      if (!uvm_config_db #(virtual apb_if)::get(this, "", "apb_vif", apb_vif))
        `uvm_fatal("DRIVER", "Failed to get apb_vif");
      apb_tmp = new(apb_vif);
      impl = apb_tmp;
      `uvm_info("DRIVER", "APB implementation selected", UVM_LOW)
    end else begin
      `uvm_fatal("DRIVER", $sformatf("Unknown protocol: %s", protocol_name));
    end
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Test transaction 1
    `uvm_info("DRIVER", "Starting Transaction 1: addr=0x1000, data=0xDEAD", UVM_LOW)
    perform_transaction(32'h1000, 32'hDEAD);
    
    #20ns;
    
    // Test transaction 2
    `uvm_info("DRIVER", "Starting Transaction 2: addr=0x2000, data=0xBEEF", UVM_LOW)
    perform_transaction(32'h2000, 32'hBEEF);
    
    #20ns;
    
    // Test transaction 3
    `uvm_info("DRIVER", "Starting Transaction 3: addr=0x3000, data=0xCAFE", UVM_LOW)
    perform_transaction(32'h3000, 32'hCAFE);
    
    phase.drop_objection(this);
  endtask
  
  task perform_transaction(bit[31:0] addr, bit[31:0] data);
    bit[31:0] response;
    impl.send_addr_phase(addr);
    impl.send_data_phase(data);
    impl.receive_response(response);
    `uvm_info("DRIVER", $sformatf("Transaction complete - Response: 0x%0h", response), UVM_MEDIUM)
  endtask
endclass

// ===== Test Base =====
class test_base extends uvm_test;
  `uvm_component_utils(test_base)
  
  driver drv;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = driver::type_id::create("drv", this);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    `uvm_info("TEST", "=== Test Environment Created ===", UVM_LOW)
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
    uvm_config_db #(string)::set(this, "drv", "protocol", "AXI4");
  endfunction
endclass

// ===== APB Test =====
class apb_test extends test_base;
  `uvm_component_utils(apb_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db #(string)::set(this, "drv", "protocol", "APB");
  endfunction
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
      axi_vif.bvalid <= axi_vif.wvalid;
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
    uvm_config_db #(virtual axi4_if)::set(null, "uvm_test_top.drv", "axi4_vif", axi_vif);
    uvm_config_db #(virtual apb_if)::set(null, "uvm_test_top.drv", "apb_vif", apb_vif);
    run_test();
  end
  
  initial begin
    #2us $finish;
  end
endmodule

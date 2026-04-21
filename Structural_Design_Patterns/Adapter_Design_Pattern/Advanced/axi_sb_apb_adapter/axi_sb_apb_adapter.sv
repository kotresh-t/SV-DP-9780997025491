/*
    Practical usage of Adapter design pattern in UVM testbench.
    In this example, we have an AXI interface and an AHB interface. The adapter class 'axi_to_apb_protocol_adapter' allows us to use the AHB interface to perform operations that are expected by the AXI interface.
    The adapter translates the AXI read/write operations into corresponding APB read/write operations, allowing components designed for AXI to work with an APB-based system without modification.
    This is particularly useful in scenarios where we have legacy components or when we want to integrate different IP blocks that use different interfaces.
*/ 
    
module tb(); 

`include "uvm_macros.svh"
import uvm_pkg::*; 

    // AXI transaction (simplified)
    class axi_transaction extends uvm_sequence_item;
      rand bit [31:0] awaddr;
      rand bit [31:0] wdata;
      rand bit        is_write;
    
      `uvm_object_utils(axi_transaction)
    
      function new(string name = "axi_transaction");
        super.new(name);
      endfunction
    endclass
    
    // APB transaction (simplified)
    class apb_transaction extends uvm_sequence_item;
      rand bit [31:0] paddr;
      rand bit [31:0] pwdata;
      rand bit        pwrite;
    
      `uvm_object_utils(apb_transaction)
    
      function new(string name = "apb_transaction");
        super.new(name);
      endfunction
    endclass

    class axi_to_apb_protocol_adapter extends uvm_component;
    
      `uvm_component_utils(axi_to_apb_protocol_adapter)
    
      // AXI input
      uvm_analysis_imp #(axi_transaction,axi_to_apb_protocol_adapter) axi_analysis_export;
    
      // APB output
      uvm_analysis_port #(apb_transaction) apb_port;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_analysis_export = new("axi_analysis_export", this);
        apb_port            = new("apb_port", this);
      endfunction
    
      // Adapter logic
      function void write(axi_transaction axi_txn);
        apb_transaction apb_txn;
    
        // Assumption: single-beat AXI write only
        if (!axi_txn.is_write) begin
          `uvm_warning("ADAPTER",
            "Read transaction ignored by AXI→APB adapter")
          return;
        end
    
        apb_txn = apb_transaction::type_id::create("apb_txn");
    
        // Protocol translation
        apb_txn.paddr  = axi_txn.awaddr;
        apb_txn.pwdata = axi_txn.wdata;
        apb_txn.pwrite = 1'b1;
    
        // Forward adapted transaction
        apb_port.write(apb_txn);
      endfunction
    
    endclass

   
    class axi_monitor extends uvm_component;
      `uvm_component_utils(axi_monitor)
    
      uvm_analysis_port #(axi_transaction) item_collected_port;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
      endfunction
    
      task run_phase(uvm_phase phase);
        axi_transaction txn;
    
        phase.raise_objection(this);
    
        // Dummy stimulus for demonstration
        txn = axi_transaction::type_id::create("txn");
        txn.awaddr   = 'h1000;
        txn.wdata    = 'hDEADBEEF;
        txn.is_write = 1'b1;
    
        item_collected_port.write(txn);
    
        phase.drop_objection(this);
      endtask
    endclass

    class apb_monitor extends uvm_component;
      `uvm_component_utils(apb_monitor)
    
      uvm_analysis_port #(apb_transaction) item_collected_port;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
      endfunction
    endclass
  
    class axi_agent extends uvm_component;
      `uvm_component_utils(axi_agent)
    
      axi_monitor monitor;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
      endfunction
    
      function void build_phase(uvm_phase phase);
        monitor = axi_monitor::type_id::create("monitor", this);
      endfunction
    endclass
    
    
    class apb_agent extends uvm_component;
      `uvm_component_utils(apb_agent)
    
      apb_monitor monitor;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
      endfunction
    
      function void build_phase(uvm_phase phase);
        monitor = apb_monitor::type_id::create("monitor", this);
      endfunction
    endclass


    class scoreboard extends uvm_component;
      `uvm_component_utils(scoreboard)
    
      // Expected (from adapter)
      uvm_analysis_imp #(apb_transaction, scoreboard) apb_collected_export;
    
      // Observed (from APB monitor)
      uvm_analysis_imp #(apb_transaction, scoreboard) apb_observed_export;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
        apb_collected_export = new("apb_collected_export", this);
        apb_observed_export  = new("apb_observed_export", this);
      endfunction
    
      function void write(apb_transaction txn);
        `uvm_info("SCOREBOARD", $sformatf("APB txn received: addr=%h data=%h",txn.paddr, txn.pwdata),UVM_MEDIUM)
      endfunction
    endclass

    class axi_apb_bridge_env extends uvm_env;
      `uvm_component_utils(axi_apb_bridge_env)
    
      axi_agent                     axi_master;
      apb_agent                     apb_slave;
      axi_to_apb_protocol_adapter   adapter;
      scoreboard                    sb;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
      endfunction
    
      function void build_phase(uvm_phase phase);
        axi_master = axi_agent::type_id::create("axi_master", this);
        apb_slave  = apb_agent::type_id::create("apb_slave", this);
        adapter    = axi_to_apb_protocol_adapter::type_id::create("adapter", this);
        sb         = scoreboard::type_id::create("sb", this);
      endfunction
    
      function void connect_phase(uvm_phase phase);
        // AXI → Adapter
        axi_master.monitor.item_collected_port.connect(adapter.axi_analysis_export);
    
        // Adapter → Scoreboard (expected)
        adapter.apb_port.connect(sb.apb_collected_export);
    
        // APB Monitor → Scoreboard (observed)
        apb_slave.monitor.item_collected_port.connect(sb.apb_observed_export);
      endfunction
    endclass

    class axi_apb_adapter_test extends uvm_test;
      `uvm_component_utils(axi_apb_adapter_test)
    
      axi_apb_bridge_env env;
    
      function new(string name, uvm_component parent);
        super.new(name, parent);
      endfunction
    
      function void build_phase(uvm_phase phase);
        env = axi_apb_bridge_env::type_id::create("env", this);
      endfunction
    endclass
 
    initial 
        begin 
            run_test("axi_apb_adapter_test"); 
        end
endmodule // tb 

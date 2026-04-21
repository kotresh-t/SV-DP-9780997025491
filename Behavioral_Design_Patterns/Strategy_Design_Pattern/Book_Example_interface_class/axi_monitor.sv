class axi_monitor extends uvm_monitor;
  virtual axi_if vif;
  uvm_analysis_port #(write_transaction) item_collected_port;
  `uvm_component_utils(axi_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  task run_phase(uvm_phase phase);
    write_transaction txn;
    forever begin
      @(posedge vif.clk iff vif.awvalid);
      txn = write_transaction::type_id::create("txn");
      txn.addr = vif.awaddr;
      txn.data = vif.wdata;
      item_collected_port.write(txn);
    end
  endtask
endclass
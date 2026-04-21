class axi_driver extends uvm_driver #(write_transaction);
  virtual axi_if vif;
  `uvm_component_utils(axi_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      vif.awaddr <= req.addr;
      vif.wdata  <= req.data;
      vif.awvalid <= 1;
      @(posedge vif.clk);
      vif.awvalid <= 0;
      seq_item_port.item_done();
    end
  endtask
endclass
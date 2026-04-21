// my_driver.sv
class my_driver extends uvm_driver #(packet);

protocol_impl impl; // ← Bridge: holds implementation

`uvm_component_utils(my_driver)

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    // Inject implementation from agent/env
    function void set_implementation(protocol_impl i);
        if (i == null) `uvm_fatal("DRV", "Null implementation!")
        impl = i;
        `uvm_info("DRIVER", $sformatf("Using implementation: %s", impl.get_name()), UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        packet req;
        forever begin
            seq_item_port.get_next_item(req);
            impl.send(req); // ← Delegates to selected implementation
            seq_item_port.item_done();
        end
    endtask
endclass
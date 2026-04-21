`ifndef uvm_my_driver_sv
`define uvm_my_driver_sv

class my_transaction extends uvm_sequence_item;
    `uvm_object_utils(my_transaction)

    rand bit [7:0] data;

    function new(string name = "my_transaction");
        super.new(name);
    endfunction

    function bit [7:0] get_data();
        return data;
    endfunction
endclass

class my_sequence extends uvm_sequence #(my_transaction);
    `uvm_object_utils(my_sequence)

    function new(string name = "my_sequence");
        super.new(name);
    endfunction

    virtual task body();
        my_transaction req;

        repeat (3) begin
            req = my_transaction::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_error(get_full_name(), "Failed to randomize my_transaction")
            end
            finish_item(req);
        end
    endtask
endclass

// A simple UVM driver
class my_driver extends uvm_driver #(my_transaction);
    `uvm_component_utils(my_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_transaction req;
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info(get_full_name(), $sformatf("Driving transaction with data: %0d", req.get_data()), UVM_LOW);
            seq_item_port.item_done();
        end
    endtask
endclass

// A simple UVM agent
class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)
    my_driver drv;
    uvm_sequencer #(my_transaction) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = my_driver::type_id::create("drv", this);
        sqr = uvm_sequencer#(my_transaction)::type_id::create("sqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass

// A simple UVM environment
class my_env extends uvm_env;
    `uvm_component_utils(my_env)
    my_agent agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = my_agent::type_id::create("agt", this);
    endfunction
endclass



`endif // uvm_my_driver_sv

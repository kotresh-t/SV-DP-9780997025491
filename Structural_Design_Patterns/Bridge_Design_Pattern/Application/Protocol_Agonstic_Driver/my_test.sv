// my_test.sv
class my_test extends uvm_test;
my_env env;
my_sequence seq;

`uvm_component_utils(my_test)

    function new(string name, uvm_component parent);
         super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        env = my_env::type_id::create("env", this);
        seq = my_sequence::type_id::create("seq");

        // 🔑 CONFIGURATION MECHANISM: Set variant here
        // Try: "eth_10g", "eth_25g", or "usb3"
        uvm_config_db#(string)::set(this, "env", "impl_type", "eth_25g");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

endclass
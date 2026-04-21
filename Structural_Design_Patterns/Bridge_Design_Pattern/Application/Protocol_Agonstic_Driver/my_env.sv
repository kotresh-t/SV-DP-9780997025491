// my_env.sv
class my_env extends uvm_env;
my_agent agt;

`uvm_component_utils(my_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = my_agent::type_id::create("agt", this);
        // Pass config down (optional, but clean)
        if (uvm_config_db#(string)::exists(this, "", "impl_type")) begin
            string t;
            void'(uvm_config_db#(string)::get(this, "", "impl_type", t));
            uvm_config_db#(string)::set(this, "agt", "impl_type", t);
        end
    endfunction
endclass
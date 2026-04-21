// packet.sv

module tb(); 

`include "uvm_macros.svh" 
import uvm_pkg::*; 

class packet extends uvm_sequence_item;
rand bit [63:0] data;
rand int        len;

`uvm_object_utils_begin(packet)
  `uvm_field_int(data, UVM_ALL_ON)
  `uvm_field_int(len, UVM_ALL_ON)
`uvm_object_utils_end

    function new(string name = "packet");
       super.new(name);
    endfunction
    
endclass
	
// my_sequencer.sv
class my_sequencer extends uvm_sequencer #(packet);

`uvm_component_utils(my_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

// protocol_impl.sv
virtual class protocol_impl extends uvm_object;
`uvm_object_utils(protocol_impl)

pure virtual task send(packet pkt);
pure virtual function string get_name();

    function new(string name = "protocol_impl");
        super.new(name);
    endfunction

endclass

// --- Concrete Implementations ---
class eth_10g_impl extends protocol_impl;
`uvm_object_utils(eth_10g_impl)

    function new(string name = "eth_10g_impl");
        super.new(name);
    endfunction

    virtual task send(packet pkt);
        `uvm_info("ETH_10G", $sformatf("Sending %0d-byte pkt @ 10G", pkt.len), UVM_MEDIUM)
        #10ns; // 10G timing
    endtask

    virtual function string get_name(); 
        return "Ethernet 10G"; 
    endfunction

endclass

class eth_25g_impl extends protocol_impl;
`uvm_object_utils(eth_25g_impl)

    function new(string name = "eth_25g_impl");
        super.new(name);
    endfunction

    virtual task send(packet pkt);
        `uvm_info("ETH_25G", $sformatf("Sending %0d-byte pkt @ 25G", pkt.len), UVM_MEDIUM)
        #4ns; // 25G timing (faster)
    endtask

    virtual function string get_name(); 
        return "Ethernet 25G"; 
    endfunction

endclass

class usb3_impl extends protocol_impl;

`uvm_object_utils(usb3_impl)

function new(string name = "usb3_impl");
    super.new(name);
endfunction

virtual task send(packet pkt);
  `uvm_info("USB3", $sformatf("Sending USB3 packet: 0x%0h", pkt.data), UVM_MEDIUM)
  #5ns;
endtask

virtual function string get_name(); 
    return "USB 3.0"; 
endfunction

endclass
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

// my_agent.sv
class my_agent extends uvm_agent;

my_sequencer sqr;
my_driver    drv;

`uvm_component_utils(my_agent)

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        // Get implementation type from config DB
        string impl_type;
        protocol_impl impl;

        super.build_phase(phase);
        
        sqr = my_sequencer::type_id::create("sqr", this);
        drv = my_driver::type_id::create("drv", this);

        if (uvm_config_db#(string)::get(this, "", "impl_type", impl_type)) begin
            case (impl_type) 
                "eth_10g": impl = eth_10g_impl::type_id::create("impl");
                "eth_25g": impl = eth_25g_impl::type_id::create("impl");
                "usb3":    impl = usb3_impl::type_id::create("impl");
                default:   `uvm_fatal("AGENT", $sformatf("Unknown impl: %s", impl_type))
            endcase
            drv.set_implementation(impl);
        end else begin
            `uvm_fatal("AGENT", "No 'impl_type' configured!")
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass
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

initial
begin
  run_test("my_test");
end


endmodule 


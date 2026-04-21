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
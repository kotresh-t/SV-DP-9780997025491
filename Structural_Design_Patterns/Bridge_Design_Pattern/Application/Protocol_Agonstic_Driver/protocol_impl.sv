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
// my_sequence.sv
class my_sequence extends uvm_sequence #(packet);
`uvm_object_utils(my_sequence)
`uvm_declare_p_sequencer(my_sequencer)

    function new(string name = "my_sequence_impl");
         super.new(name);
    endfunction
    
    task body();
        repeat (3) begin
            packet pkt = packet::type_id::create("pkt");
            start_item(pkt);
            assert(pkt.randomize() with { len inside {[64:1500]}; });
            finish_item(pkt);
        end
    endtask

endclass
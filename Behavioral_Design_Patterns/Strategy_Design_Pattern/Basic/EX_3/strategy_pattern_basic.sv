Dynamic Behavior (Strategy Pattern):
// Behavior selected at runtime
class flexible_sequence extends uvm_sequence;
addr_strategy addr_gen;
data_strategy data_gen;
    virtual task body();
        req = sequence_item::type_id::create("req");
	  // Behavior determined by strategy
        req.addr = addr_gen.next_address();
  	 // Can change at runtime
        req.data = data_gen.next_data(); 
        finish_item(req);
         // ... more operations using strategies ...
    endtask
endclass
// At runtime, choose different strategies
initial begin
    my_seq.addr_gen = new sequential_address_strategy();
    my_seq.data_gen = new random_data_strategy();
    my_seq.start(null);
    // Later, change behavior
    my_seq.addr_gen = new weighted_address_strategy();
    my_seq.start(null);
end

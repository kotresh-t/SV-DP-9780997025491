// Concrete Strategies:
// Sequential addressing strategy
class sequential_address_strategy extends address_strategy;
`uvm_object_utils(sequential_address_strategy)
logic [31:0] current_addr = 32'h0000_0000;
logic [31:0] addr_increment = 32'h0000_0004;

  function new(string name = "sequential_address_strategy");
      super.new(name);
  endfunction
 
  virtual function logic [31:0] next_address();
    logic [31:0] addr = current_addr;
    current_addr = current_addr + addr_increment;
    return addr;
  endfunction

  virtual function void reset();
    current_addr = 32'h0000_0000;
  endfunction
endclass

// Random address strategy
class random_address_strategy extends address_strategy;
`uvm_object_utils(random_address_strategy)
 
  function new(string name = "random_address_strategy");
    super.new(name);
  endfunction
  
  virtual function logic [31:0] next_address();
    logic [31:0] addr;
    void'(std::randomize(addr) with {
        addr[1:0] == 2'b00; // Word-aligned
    });
    return addr;
  endfunction
  
  virtual function void reset();
  // Nothing to reset for random
  endfunction
endclass

// Weighted addressing (hot spots)
class weighted_address_strategy extends address_strategy;
`uvm_object_utils(weighted_address_strategy)

logic [31:0] hot_addresses[10] = '{
    32'h1000_0000, 32'h2000_0000, 32'h3000_0000,
    32'h4000_0000, 32'h5000_0000, 32'h6000_0000,
    32'h7000_0000, 32'h8000_0000, 32'h9000_0000,
    32'hA000_0000
};

int hot_weight = 70; // 70% of accesses to hot spots
  function new(string name = "weighted_address_strategy");
      super.new(name);
  endfunction
  
  virtual function logic [31:0] next_address();
    int choice;
    void'(std::randomize(choice) with { choice dist {[0:69] := 70, [70:99] := 30}; });
    if (choice < hot_weight) begin
    return hot_addresses[$urandom_range(9, 0)];
    end else begin
    logic [31:0] addr;
    void'(std::randomize(addr) with { addr[1:0] == 2'b00; });
    return addr;
    end
  endfunction
 
  virtual function void reset();
  endfunction

endclass

// Context (Sequence Using Strategy):
class flexible_write_sequence extends uvm_sequence #(write_transaction);
`uvm_object_utils(flexible_write_sequence)
// Strategy object - can be set to any concrete strategy
address_strategy addr_strategy;
int num_transactions = 100;
    
    function new(string name = "flexible_write_sequence");
      super.new(name);
    endfunction
  
    virtual task body();
        write_transaction req;
        // Use default random strategy if none set
        if (addr_strategy == null) begin
            addr_strategy = random_address_strategy::type_id::create("addr_strategy");
        end

        for (int i = 0; i < num_transactions; i++) begin
            req = write_transaction::type_id::create("req");
        
            // Delegate address generation to strategy
            req.addr = addr_strategy.next_address();
            req.data = $urandom();
        
            start_item(req);
            finish_item(req);
        end
    endtask
endclass




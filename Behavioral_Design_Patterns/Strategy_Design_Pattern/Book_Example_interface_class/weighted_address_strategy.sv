// weighted_address_strategy.sv
class weighted_address_strategy extends uvm_object implements address_strategy;
  logic [31:0] hot_addresses[10];
  int hot_weight;
  int index;

  `uvm_object_utils(weighted_address_strategy)

  function new(string name = "weighted_address_strategy");
    super.new(name);
    reset();
  endfunction

  virtual function logic [31:0] next_address();
    if ($urandom_range(0, 99) < hot_weight) begin
      // Return hot address
      return hot_addresses[index % 10];
    end else begin
      // Return random
      return $urandom();
    end
  endfunction

  virtual function void reset();
    hot_weight = 50; // 50% chance of hot address
    for (int i = 0; i < 10; i++) begin
      hot_addresses[i] = 32'h1000 + i * 4;
    end
    index = 0;
  endfunction
endclass
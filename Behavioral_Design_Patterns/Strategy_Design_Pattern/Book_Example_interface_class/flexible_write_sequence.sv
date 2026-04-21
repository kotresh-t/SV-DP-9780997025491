// flexible_write_sequence.sv
class flexible_write_sequence extends uvm_sequence #(write_transaction);
  address_strategy addr_strategy; // ← Context holds strategy
  int num_transactions = 10;

  `uvm_object_utils(flexible_write_sequence)

  function new(string name = "flexible_write_sequence");
    super.new(name);
  endfunction

  // Set strategy at runtime
  function void set_strategy(address_strategy strat);
    this.addr_strategy = strat;
  endfunction

  task body();
    write_transaction req;
    repeat (num_transactions) begin
      req = write_transaction::type_id::create("req");
      req.addr = addr_strategy.next_address();
      req.data = $urandom();

      start_item(req);
      finish_item(req);
    end
  endtask

  // Optional: Reset strategy
  function void reset_strategy();
    if (addr_strategy != null)
      addr_strategy.reset();
  endfunction
endclass
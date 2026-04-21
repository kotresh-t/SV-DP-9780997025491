// Use Case 3: Constraint Violation Analysis
//
// Simple Iterator Pattern example:
// 1. Store all transactions in a collection
// 2. Build a filtered iterator that only exposes violating transactions
// 3. Analyze only the failing items without changing the collection itself

class bus_transaction;
  string     name;
  bit [31:0] addr;
  bit [31:0] data;
  bit        violation_detected;
  string     violation_reason;

  function new(
    string     name = "txn",
    bit [31:0] addr = '0,
    bit [31:0] data = '0,
    bit        violation_detected = 0,
    string     violation_reason = ""
  );
    this.name               = name;
    this.addr               = addr;
    this.data               = data;
    this.violation_detected = violation_detected;
    this.violation_reason   = violation_reason;
  endfunction

  function string convert2string();
    return $sformatf(
      "name=%s addr=0x%08h data=0x%08h violation=%0b reason=%s",
      name, addr, data, violation_detected, violation_reason
    );
  endfunction
endclass

virtual class transaction_filter;
  pure virtual function bit accept(bus_transaction txn);
endclass

class violation_filter extends transaction_filter;
  virtual function bit accept(bus_transaction txn);
    return (txn != null) && txn.violation_detected;
  endfunction
endclass

class transaction_iterator;
  protected bus_transaction items[$];
  protected int             index;

  function new();
    reset();
  endfunction

  function void set_collection(bus_transaction coll[$]);
    items = coll;
    reset();
  endfunction

  function bit has_next();
    return (index < items.size());
  endfunction

  function bus_transaction next();
    if (!has_next()) begin
      return null;
    end
    return items[index++];
  endfunction

  function void reset();
    index = 0;
  endfunction

  function int size();
    return items.size();
  endfunction
endclass

class transaction_collection;
  protected bus_transaction items[$];

  function void add(bus_transaction txn);
    items.push_back(txn);
  endfunction

  function transaction_iterator create_filtered_iterator(transaction_filter filter);
    transaction_iterator iter;
    bus_transaction filtered[$];

    foreach (items[i]) begin
      if ((filter == null) || filter.accept(items[i])) begin
        filtered.push_back(items[i]);
      end
    end

    iter = new();
    iter.set_collection(filtered);
    return iter;
  endfunction
endclass

class violation_analyzer;
  static task analyze_violation(bus_transaction txn);
    $display("Violation found -> %s", txn.convert2string());
  endtask

  static task analyze_violations(transaction_collection coll);
    transaction_iterator iter;
    violation_filter     filter;
    bus_transaction      txn;
    int                  violation_count;

    filter = new();
    iter = coll.create_filtered_iterator(filter);
    violation_count = 0;

    $display("\n--- Constraint Violation Analysis ---");

    while (iter.has_next()) begin
      txn = iter.next();
      analyze_violation(txn);
      violation_count++;
    end

    if (violation_count == 0) begin
      $display("No constraint violations found.");
    end
    else begin
      $display("Total violations: %0d", violation_count);
    end
  endtask
endclass

module constraint_violator_iter_demo;
  initial begin
    transaction_collection coll;
    bus_transaction        txn;

    coll = new();

    txn = new("txn_0", 32'h0000_0010, 32'hAAAA_5555, 0, "");
    coll.add(txn);

    txn = new("txn_1", 32'h0000_0014, 32'hFFFF_0000, 1, "Address alignment error");
    coll.add(txn);

    txn = new("txn_2", 32'h0000_0018, 32'h1234_5678, 0, "");
    coll.add(txn);

    txn = new("txn_3", 32'h0000_001C, 32'hDEAD_BEEF, 1, "Protected region access");
    coll.add(txn);

    violation_analyzer::analyze_violations(coll);
    $finish;
  end
endmodule

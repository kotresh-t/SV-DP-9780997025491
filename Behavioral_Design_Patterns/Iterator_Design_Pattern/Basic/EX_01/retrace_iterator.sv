// Use Case 1: Retrace Failed Test
//
// Simple Iterator Pattern example:
// 1. Store the failure history in a collection
// 2. Create a reverse iterator
// 3. Walk the transactions backwards to retrace how the failure happened

class retrace_bus_transaction;
  string     name;
  bit [31:0] addr;
  bit [31:0] data;
  string     phase;
  string     status;

  function new(
    string     name = "txn",
    bit [31:0] addr = '0,
    bit [31:0] data = '0,
    string     phase = "RUN",
    string     status = "OK"
  );
    this.name   = name;
    this.addr   = addr;
    this.data   = data;
    this.phase  = phase;
    this.status = status;
  endfunction

  function string convert2string();
    return $sformatf(
      "name=%s phase=%s status=%s addr=0x%08h data=0x%08h",
      name, phase, status, addr, data
    );
  endfunction
endclass

class retrace_reverse_iterator;
  protected retrace_bus_transaction items[$];
  protected int                     index;

  function new();
    reset();
  endfunction

  function void set_collection(retrace_bus_transaction coll[$]);
    items = coll;
    reset();
  endfunction

  function bit has_next();
    return (index >= 0);
  endfunction

  function retrace_bus_transaction next();
    if (!has_next()) begin
      return null;
    end
    return items[index--];
  endfunction

  function void reset();
    index = items.size() - 1;
  endfunction
endclass

class retrace_transaction_collection;
  protected retrace_bus_transaction items[$];

  function void add(retrace_bus_transaction txn);
    items.push_back(txn);
  endfunction

  function retrace_reverse_iterator create_reverse_iterator();
    retrace_reverse_iterator iter;

    iter = new();
    iter.set_collection(items);
    return iter;
  endfunction
endclass

class retrace_analyzer;
  static task retrace_failure(retrace_transaction_collection failed_txns);
    retrace_reverse_iterator iter;
    retrace_bus_transaction  txn;
    int                      step;

    iter = failed_txns.create_reverse_iterator();
    step = 0;

    $display("\n--- Retracing Failed Test ---");

    while (iter.has_next()) begin
      txn = iter.next();
      $display("Step %0d -> %s", step, txn.convert2string());
      step++;
    end
  endtask
endclass

module retrace_iterator_demo;
  initial begin
    retrace_transaction_collection failed_txns;
    retrace_bus_transaction        txn;

    failed_txns = new();

    txn = new("txn_0", 32'h0000_1000, 32'h1111_AAAA, "SETUP", "OK");
    failed_txns.add(txn);

    txn = new("txn_1", 32'h0000_1004, 32'h2222_BBBB, "CONFIG", "OK");
    failed_txns.add(txn);

    txn = new("txn_2", 32'h0000_1008, 32'h3333_CCCC, "ACCESS", "RETRY");
    failed_txns.add(txn);

    txn = new("txn_3", 32'h0000_100C, 32'h4444_DDDD, "CHECK", "FAIL");
    failed_txns.add(txn);

    retrace_analyzer::retrace_failure(failed_txns);
    $finish;
  end
endmodule
/*
# --- Retracing Failed Test ---
# Step 0 -> name=txn_3 phase=CHECK status=FAIL addr=0x0000100c data=0x4444dddd
# Step 1 -> name=txn_2 phase=ACCESS status=RETRY addr=0x00001008 data=0x3333cccc
# Step 2 -> name=txn_1 phase=CONFIG status=OK addr=0x00001004 data=0x2222bbbb
# Step 3 -> name=txn_0 phase=SETUP status=OK addr=0x00001000 data=0x1111aaaa
*/

// Use Case 2: Coverage Statistics
//
// Simple Iterator Pattern example:
// 1. Store transactions in a collection
// 2. Create a forward iterator
// 3. Walk the transactions once to compute simple statistics

typedef enum bit { READ, WRITE } coverage_cmd_e;

class coverage_bus_transaction;
  string         name;
  coverage_cmd_e command;
  bit [31:0]     addr;
  bit [31:0]     data;

  function new(
    string         name = "txn",
    coverage_cmd_e command = READ,
    bit [31:0]     addr = '0,
    bit [31:0]     data = '0
  );
    this.name    = name;
    this.command = command;
    this.addr    = addr;
    this.data    = data;
  endfunction

  function string convert2string();
    return $sformatf(
      "name=%s cmd=%s addr=0x%08h data=0x%08h",
      name, (command == READ) ? "READ" : "WRITE", addr, data
    );
  endfunction
endclass

class coverage_forward_iterator;
  protected coverage_bus_transaction items[$];
  protected int                      index;

  function new();
    reset();
  endfunction

  function void set_collection(coverage_bus_transaction coll[$]);
    items = coll;
    reset();
  endfunction

  function bit has_next();
    return (index < items.size());
  endfunction

  function coverage_bus_transaction next();
    if (!has_next()) begin
      return null;
    end
    return items[index++];
  endfunction

  function void reset();
    index = 0;
  endfunction
endclass

class coverage_transaction_collection;
  protected coverage_bus_transaction items[$];

  function void add(coverage_bus_transaction txn);
    items.push_back(txn);
  endfunction

  function coverage_forward_iterator create_forward_iterator();
    coverage_forward_iterator iter;

    iter = new();
    iter.set_collection(items);
    return iter;
  endfunction

  function int size();
    return items.size();
  endfunction
endclass

class coverage_stats;
  static task print_coverage_stats(coverage_transaction_collection coll);
    coverage_forward_iterator iter;
    coverage_bus_transaction  txn;
    int                       read_count;
    int                       write_count;

    iter = coll.create_forward_iterator();
    read_count = 0;
    write_count = 0;

    $display("\n--- Coverage Statistics ---");

    while (iter.has_next()) begin
      txn = iter.next();
      $display("Seen -> %s", txn.convert2string());

      if (txn.command == READ) begin
        read_count++;
      end
      else begin
        write_count++;
      end
    end

    $display("Total transactions: %0d", coll.size());
    $display("Reads : %0d", read_count);
    $display("Writes: %0d", write_count);
  endtask
endclass

module coverage_iterator_demo;
  initial begin
    coverage_transaction_collection coll;
    coverage_bus_transaction        txn;

    coll = new();

    txn = new("txn_0", READ,  32'h0000_2000, 32'hAAAA_0001);
    coll.add(txn);

    txn = new("txn_1", WRITE, 32'h0000_2004, 32'hBBBB_0002);
    coll.add(txn);

    txn = new("txn_2", READ,  32'h0000_2008, 32'hCCCC_0003);
    coll.add(txn);

    txn = new("txn_3", WRITE, 32'h0000_200C, 32'hDDDD_0004);
    coll.add(txn);

    coverage_stats::print_coverage_stats(coll);
    $finish;
  end
endmodule


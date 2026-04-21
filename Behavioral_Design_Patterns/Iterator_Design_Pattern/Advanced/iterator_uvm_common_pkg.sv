package iterator_uvm_common_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum bit { ITER_READ, ITER_WRITE } iterator_cmd_e;
typedef enum int unsigned {
  ITER_STATUS_OK,
  ITER_STATUS_RETRY,
  ITER_STATUS_FAIL
} iterator_status_e;

class iterator_txn extends uvm_sequence_item;
  rand iterator_cmd_e    cmd;
  rand bit [31:0]        addr;
  rand bit [31:0]        data;
  int unsigned           seq_id;
  string                 phase_name;
  iterator_status_e      status;
  bit                    violation_detected;
  string                 violation_reason;

  `uvm_object_utils_begin(iterator_txn)
    `uvm_field_enum(iterator_cmd_e, cmd, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(seq_id, UVM_ALL_ON)
    `uvm_field_string(phase_name, UVM_ALL_ON)
    `uvm_field_enum(iterator_status_e, status, UVM_ALL_ON)
    `uvm_field_int(violation_detected, UVM_ALL_ON)
    `uvm_field_string(violation_reason, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "iterator_txn");
    super.new(name);
    phase_name = "RUN";
    status = ITER_STATUS_OK;
    violation_reason = "";
  endfunction

  function string convert2string();
    string cmd_s;
    string status_s;

    cmd_s = (cmd == ITER_READ) ? "READ" : "WRITE";

    case (status)
      ITER_STATUS_OK:    status_s = "OK";
      ITER_STATUS_RETRY: status_s = "RETRY";
      default:           status_s = "FAIL";
    endcase

    return $sformatf(
      "id=%0d cmd=%s phase=%s status=%s addr=0x%08h data=0x%08h violation=%0b reason=%s",
      seq_id, cmd_s, phase_name, status_s, addr, data, violation_detected, violation_reason
    );
  endfunction
endclass

virtual class generic_iterator #(type T = iterator_txn) extends uvm_object;
  function new(string name = "generic_iterator");
    super.new(name);
  endfunction

  pure virtual function bit has_next();
  pure virtual function T get_next();
  pure virtual function void reset();
  pure virtual function int get_size();
endclass

class queue_iterator #(type T = iterator_txn) extends generic_iterator #(T);
  protected T collection[$];
  protected int current_index;

  function new(string name = "queue_iterator");
    super.new(name);
    current_index = 0;
  endfunction

  function void set_collection(T coll[$]);
    collection = coll;
    reset();
  endfunction

  function bit has_next();
    return (current_index < collection.size());
  endfunction

  function T get_next();
    if (!has_next()) begin
      return null;
    end
    return collection[current_index++];
  endfunction

  function void reset();
    current_index = 0;
  endfunction

  function int get_size();
    return collection.size();
  endfunction
endclass

class reverse_iterator #(type T = iterator_txn) extends generic_iterator #(T);
  protected T collection[$];
  protected int current_index;

  function new(string name = "reverse_iterator");
    super.new(name);
    current_index = -1;
  endfunction

  function void set_collection(T coll[$]);
    collection = coll;
    reset();
  endfunction

  function bit has_next();
    return (current_index >= 0);
  endfunction

  function T get_next();
    if (!has_next()) begin
      return null;
    end
    return collection[current_index--];
  endfunction

  function void reset();
    current_index = collection.size() - 1;
  endfunction

  function int get_size();
    return collection.size();
  endfunction
endclass

virtual class filter_predicate #(type T = iterator_txn) extends uvm_object;
  function new(string name = "filter_predicate");
    super.new(name);
  endfunction

  pure virtual function bit match(T item);
endclass

class filtered_iterator #(type T = iterator_txn) extends generic_iterator #(T);
  protected T source_collection[$];
  protected T filtered_collection[$];
  protected int current_index;
  protected filter_predicate #(T) predicate;

  function new(string name = "filtered_iterator");
    super.new(name);
    current_index = 0;
  endfunction

  function void set_collection(T coll[$]);
    source_collection = coll;
    apply_filter();
  endfunction

  function void set_filter(filter_predicate #(T) pred);
    predicate = pred;
    apply_filter();
  endfunction

  function void apply_filter();
    filtered_collection.delete();
    current_index = 0;

    foreach (source_collection[i]) begin
      if ((predicate == null) || predicate.match(source_collection[i])) begin
        filtered_collection.push_back(source_collection[i]);
      end
    end
  endfunction

  function bit has_next();
    return (current_index < filtered_collection.size());
  endfunction

  function T get_next();
    if (!has_next()) begin
      return null;
    end
    return filtered_collection[current_index++];
  endfunction

  function void reset();
    current_index = 0;
  endfunction

  function int get_size();
    return filtered_collection.size();
  endfunction
endclass

class iterator_transaction_collection extends uvm_object;
  protected iterator_txn transactions[$];

  `uvm_object_utils(iterator_transaction_collection)

  function new(string name = "iterator_transaction_collection");
    super.new(name);
  endfunction

  function void add(iterator_txn txn);
    iterator_txn txn_copy;

    if (txn == null) begin
      return;
    end

    $cast(txn_copy, txn.clone());
    if (txn_copy == null) begin
      txn_copy = txn;
    end

    transactions.push_back(txn_copy);
  endfunction

  function int get_size();
    return transactions.size();
  endfunction

  function void clear();
    transactions.delete();
  endfunction

  function queue_iterator #(iterator_txn) create_forward_iterator();
    queue_iterator #(iterator_txn) iter;

    iter = new("forward_iter");
    iter.set_collection(transactions);
    return iter;
  endfunction

  function reverse_iterator #(iterator_txn) create_reverse_iterator();
    reverse_iterator #(iterator_txn) iter;

    iter = new("reverse_iter");
    iter.set_collection(transactions);
    return iter;
  endfunction

  function filtered_iterator #(iterator_txn) create_filtered_iterator(
    filter_predicate #(iterator_txn) pred
  );
    filtered_iterator #(iterator_txn) iter;

    iter = new("filtered_iter");
    iter.set_filter(pred);
    iter.set_collection(transactions);
    return iter;
  endfunction
endclass

class iterator_source extends uvm_component;
  `uvm_component_utils(iterator_source)

  uvm_analysis_port #(iterator_txn) ap;
  protected iterator_txn stimulus[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void add_txn(iterator_txn txn);
    iterator_txn txn_copy;

    if (txn == null) begin
      return;
    end

    $cast(txn_copy, txn.clone());
    if (txn_copy == null) begin
      txn_copy = txn;
    end

    stimulus.push_back(txn_copy);
  endfunction

  function int get_num_txns();
    return stimulus.size();
  endfunction

  task run_phase(uvm_phase phase);
    iterator_txn txn;

    foreach (stimulus[i]) begin
      $cast(txn, stimulus[i].clone());
      if (txn == null) begin
        txn = stimulus[i];
      end

      `uvm_info(
        get_type_name(),
        $sformatf("Publishing %s", txn.convert2string()),
        UVM_MEDIUM
      )
      ap.write(txn);
      #1ns;
    end
  endtask
endclass

endpackage


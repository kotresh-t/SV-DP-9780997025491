// Iterator Design Pattern: Traversing Different Data Structures in SystemVerilog
// This example demonstrates how to use iterators to traverse queues, arrays, and associative arrays

// ============================================================================
// Iterator Interface - Defines the interface for iterators
// ============================================================================
class Iterator_Interface;
  typedef int data_type;

  function bit has_next();
    // To be implemented by subclass
  endfunction

  function data_type next();
    // To be implemented by subclass
  endfunction

  function void reset();
    // To be implemented by subclass
  endfunction
endclass

// ============================================================================
// Array Iterator - Iterates through dynamic arrays
// ============================================================================
class ArrayIterator;
  local int data_array[];
  local int current_index;
  
  function new(int arr[]);
    data_array = new[arr.size()];
    data_array = arr;
    current_index = 0;
  endfunction
  
  function bit has_next();
    return (current_index < data_array.size());
  endfunction
  
  function int next();
    if (has_next()) begin
      return data_array[current_index++];
    end else begin
      $display("Error: No more elements in array");
      return -1;
    end
  endfunction
  
  function void reset();
    current_index = 0;
  endfunction
endclass

// ============================================================================
// Queue Iterator - Iterates through queue
// ============================================================================
class QueueIterator;
  local int data_queue[$];
  local int current_index;
  
  function new(int queue[$]);
    data_queue = queue;
    current_index = 0;
  endfunction
  
  function bit has_next();
    return (current_index < data_queue.size());
  endfunction
  
  function int next();
    if (has_next()) begin
      return data_queue[current_index++];
    end else begin
      $display("Error: No more elements in queue");
      return -1;
    end
  endfunction
  
  function void reset();
    current_index = 0;
  endfunction
endclass

// ============================================================================
// Associative Array Iterator - Iterates through associative arrays
// ============================================================================
class AssociativeArrayIterator;
  local int data_aa[string];
  local string keys[$];
  local int current_index;
  
  function new(int aa[string]);
    data_aa = aa;
    keys = aa.find() with (1);  // Get all keys
    current_index = 0;
  endfunction
  
  function bit has_next();
    return (current_index < keys.size());
  endfunction
  
  function string next_key();
    if (has_next()) begin
      return keys[current_index++];
    end else begin
      $display("Error: No more elements in associative array");
      return "";
    end
  endfunction
  
  function int get_value(string key);
    return data_aa[key];
  endfunction
  
  function void reset();
    current_index = 0;
  endfunction
endclass

// ============================================================================
// Collection Interface - Defines interface for collections
// ============================================================================
interface Collection_Interface;
  class Iterator_Base;
    virtual function bit has_next();
    virtual function int next();
    virtual function void reset();
  endclass
endinterface

// ============================================================================
// Concrete Collections - Wrapper classes for data structures
// ============================================================================

// Array Collection
class ArrayCollection;
  local int arr[];
  
  function new(int array[]);
    arr = new[array.size()];
    arr = array;
  endfunction
  
  function ArrayIterator create_iterator();
    return new(arr);
  endfunction
endclass

// Queue Collection
class QueueCollection;
  local int q[$];
  
  function new(int queue[$]);
    q = queue;
  endfunction
  
  function QueueIterator create_iterator();
    return new(q);
  endfunction
endclass

// Associative Array Collection
class AssociativeArrayCollection;
  local int aa[string];
  
  function new(int assoc_array[string]);
    aa = assoc_array;
  endfunction
  
  function AssociativeArrayIterator create_iterator();
    AssociativeArrayIterator iter;
    iter = this.new(aa);
    return iter;
  endfunction
endclass

// ============================================================================
// Testbench - Demonstrates the Iterator pattern usage
// ============================================================================
module iterator_pattern_tb;
  
  initial begin
    $display("\n========================================");
    $display("Iterator Design Pattern Example");
    $display("========================================\n");
    
    // Test 1: Array Iterator
    $display("--- Test 1: Array Iterator ---");
    test_array_iterator();
    
    // Test 2: Queue Iterator
    $display("\n--- Test 2: Queue Iterator ---");
    test_queue_iterator();
    
    // Test 3: Associative Array Iterator
    $display("\n--- Test 3: Associative Array Iterator ---");
    test_associative_array_iterator();
    
    $display("\n========================================\n");
    $finish;
  end
  
  // ========== Test Functions ==========
  
  task test_array_iterator();
    int arr[] = '{10, 20, 30, 40, 50};
    ArrayIterator arr_iter;
    int value;
    
    $display("Array elements: %p", arr);
    
    arr_iter = new(arr);
    
    $display("Traversing array using iterator:");
    while (arr_iter.has_next()) begin
      value = arr_iter.next();
      $display("  Value: %d", value);
    end
    
    // Reset and traverse again
    $display("After reset, traversing again:");
    arr_iter.reset();
    while (arr_iter.has_next()) begin
      value = arr_iter.next();
      $display("  Value: %d", value);
    end
  endtask
  
  task test_queue_iterator();
    int q[$] = '{100, 200, 300, 400};
    QueueIterator q_iter;
    int value;
    
    $display("Queue elements: %p", q);
    
    q_iter = new(q);
    
    $display("Traversing queue using iterator:");
    while (q_iter.has_next()) begin
      value = q_iter.next();
      $display("  Value: %d", value);
    end
    
    // Reset and traverse again
    $display("After reset, traversing again:");
    q_iter.reset();
    while (q_iter.has_next()) begin
      value = q_iter.next();
      $display("  Value: %d", value);
    end
  endtask
  
  task test_associative_array_iterator();
    int aa[string];
    AssociativeArrayIterator aa_iter;
    string key;
    
    // Initialize associative array
    aa["Apple"] = 50;
    aa["Banana"] = 75;
    aa["Cherry"] = 30;
    aa["Date"] = 60;
    
    $display("Associative array entries:");
    foreach (aa[k]) begin
      $display("  Key: %s, Value: %d", k, aa[k]);
    end
    
    aa_iter = new(aa);
    
    $display("Traversing associative array using iterator:");
    while (aa_iter.has_next()) begin
      key = aa_iter.next_key();
      $display("  Key: %s, Value: %d", key, aa_iter.get_value(key));
    end
    
    // Reset and traverse again
    $display("After reset, traversing again:");
    aa_iter.reset();
    while (aa_iter.has_next()) begin
      key = aa_iter.next_key();
      $display("  Key: %s, Value: %d", key, aa_iter.get_value(key));
    end
  endtask

endmodule

// filepath: Iterator_Design_Pattern/UVM_Iterator_Patterns.sv
// Comprehensive Iterator Pattern Examples Applied to UVM Methodology

`ifndef UVM_ITERATOR_PATTERNS_SV
`define UVM_ITERATOR_PATTERNS_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// ============================================================================
// Part 1: Transaction Definition
// ============================================================================
class uvm_transaction_example extends uvm_sequence_item;
    `uvm_object_utils(uvm_transaction_example)
    
    rand bit [7:0]  opcode;
    rand bit [31:0] address;
    rand bit [31:0] data;
    bit [31:0]      timestamp;
    
    function new(string name = "uvm_transaction_example");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("[OP:0x%02h ADDR:0x%08h DATA:0x%08h TS:%0t]",
                        opcode, address, data, timestamp);
    endfunction
endclass

// ============================================================================
// Part 2: Generic Iterator Interface (Reusable for UVM)
// ============================================================================
virtual class generic_iterator #(type T) extends uvm_object;
    `uvm_object_param_utils(generic_iterator #(T))
    
    function new(string name = "generic_iterator");
        super.new(name);
    endfunction
    
    pure virtual function bit has_next();
    pure virtual function T get_next();
    pure virtual function void reset();
    pure virtual function int get_size();
endclass

// ============================================================================
// Part 3: Concrete Iterators for Different Collections
// ============================================================================

// Queue Iterator - For transaction queues
class queue_iterator #(type T) extends generic_iterator #(T);
    `uvm_object_param_utils(queue_iterator #(T))
    
    local T collection[$];
    local int current_index = 0;
    
    function new(string name = "queue_iterator");
        super.new(name);
    endfunction
    
    function void set_collection(T coll[$]);
        collection = coll;
        reset();
    endfunction
    
    function bit has_next();
        return (current_index < collection.size());
    endfunction
    
    function T get_next();
        if (has_next()) begin
            return collection[current_index++];
        end
        `uvm_error(get_type_name(), "No more elements in collection")
        return null;
    endfunction
    
    function void reset();
        current_index = 0;
    endfunction
    
    function int get_size();
        return collection.size();
    endfunction
endclass

// Reverse Iterator - Traverse queue backwards
class reverse_iterator #(type T) extends generic_iterator #(T);
    `uvm_object_param_utils(reverse_iterator #(T))
    
    local T collection[$];
    local int current_index;
    
    function new(string name = "reverse_iterator");
        super.new(name);
    endfunction
    
    function void set_collection(T coll[$]);
        collection = coll;
        reset();
    endfunction
    
    function bit has_next();
        return (current_index >= 0);
    endfunction
    
    function T get_next();
        if (has_next()) begin
            return collection[current_index--];
        end
        `uvm_error(get_type_name(), "No more elements in collection")
        return null;
    endfunction
    
    function void reset();
        current_index = collection.size() - 1;
    endfunction
    
    function int get_size();
        return collection.size();
    endfunction
endclass

// Filtered Iterator - Only returns elements matching criteria
class filtered_iterator #(type T) extends generic_iterator #(T);
    `uvm_object_param_utils(filtered_iterator #(T))
    
    local T source_collection[$];
    local T filtered_collection[$];
    local int current_index = 0;
    local bit function_handle[string];
    
    typedef bit function(T) filter_func_t;
    local filter_func_t filter_function;
    
    function new(string name = "filtered_iterator");
        super.new(name);
    endfunction
    
    function void set_collection(T coll[$]);
        source_collection = coll;
        apply_filter();
    endfunction
    
    function void set_filter(filter_func_t func);
        filter_function = func;
        apply_filter();
    endfunction
    
    function void apply_filter();
        filtered_collection.delete();
        current_index = 0;
        foreach (source_collection[i]) begin
            if (filter_function != null) begin
                if (filter_function(source_collection[i])) begin
                    filtered_collection.push_back(source_collection[i]);
                end
            end
        end
    endfunction
    
    function bit has_next();
        return (current_index < filtered_collection.size());
    endfunction
    
    function T get_next();
        if (has_next()) begin
            return filtered_collection[current_index++];
        end
        `uvm_error(get_type_name(), "No more elements in filtered collection")
        return null;
    endfunction
    
    function void reset();
        current_index = 0;
    endfunction
    
    function int get_size();
        return filtered_collection.size();
    endfunction
endclass

// ============================================================================
// Part 4: Collection Container (Aggregate Pattern + Iterator)
// ============================================================================
class transaction_collection extends uvm_object;
    `uvm_object_utils(transaction_collection)
    
    local uvm_transaction_example transactions[$];
    local int max_size = 1000;
    
    function new(string name = "transaction_collection");
        super.new(name);
    endfunction
    
    function void add(uvm_transaction_example txn);
        if (transactions.size() < max_size) begin
            transactions.push_back(txn);
        end else begin
            `uvm_error(get_type_name(), 
                      "Collection size limit reached")
        end
    endfunction
    
    function queue_iterator #(uvm_transaction_example) create_iterator();
        queue_iterator #(uvm_transaction_example) iter;
        iter = new("queue_iterator");
        iter.set_collection(transactions);
        return iter;
    endfunction
    
    function reverse_iterator #(uvm_transaction_example) 
        create_reverse_iterator();
        reverse_iterator #(uvm_transaction_example) iter;
        iter = new("reverse_iterator");
        iter.set_collection(transactions);
        return iter;
    endfunction
    
    function int get_size();
        return transactions.size();
    endfunction
    
    function void clear();
        transactions.delete();
    endfunction
    
    function void print_collection();
        queue_iterator #(uvm_transaction_example) iter;
        uvm_transaction_example txn;
        
        `uvm_info(get_type_name(), "===== Transaction Collection =====", 
                 UVM_LOW)
        
        iter = create_iterator();
        while (iter.has_next()) begin
            txn = iter.get_next();
            `uvm_info(get_type_name(), 
                     $sformatf("[%0d] %s", iter.get_size() - 
                               iter.get_size() + 1, txn.convert2string()), 
                     UVM_LOW)
        end
    endfunction
endclass

// ============================================================================
// Part 5: Component Hierarchy Iterator (UVM-specific)
// ============================================================================
class component_hierarchy_iterator extends uvm_object;
    `uvm_object_utils(component_hierarchy_iterator)
    
    local uvm_component root_component;
    local uvm_component components[$];
    local int current_index = 0;
    local bit depth_first;
    
    function new(string name = "component_hierarchy_iterator", 
                 bit is_depth_first = 1);
        super.new(name);
        depth_first = is_depth_first;
    endfunction
    
    function void set_root(uvm_component root);
        root_component = root;
        build_hierarchy_list();
    endfunction
    
    function void build_hierarchy_list();
        components.delete();
        current_index = 0;
        if (depth_first)
            traverse_depth_first(root_component);
        else
            traverse_breadth_first(root_component);
    endfunction
    
    function void traverse_depth_first(uvm_component comp);
        if (comp == null) return;
        components.push_back(comp);
        
        for (int i = 0; i < comp.get_num_children(); i++) begin
            uvm_component child;
            child = comp.get_child(i);
            if (child != null)
                traverse_depth_first(child);
        end
    endfunction
    
    function void traverse_breadth_first(uvm_component comp);
        uvm_component queue[$];
        uvm_component current;
        int child_count;
        
        if (comp == null) return;
        queue.push_back(comp);
        
        while (queue.size() > 0) begin
            current = queue.pop_front();
            components.push_back(current);
            
            child_count = current.get_num_children();
            for (int i = 0; i < child_count; i++) begin
                uvm_component child = current.get_child(i);
                if (child != null)
                    queue.push_back(child);
            end
        end
    endfunction
    
    function bit has_next();
        return (current_index < components.size());
    endfunction
    
    function uvm_component get_next();
        if (has_next()) begin
            return components[current_index++];
        end
        `uvm_error(get_type_name(), "No more components in hierarchy")
        return null;
    endfunction
    
    function void reset();
        current_index = 0;
    endfunction
    
    function void print_hierarchy();
        uvm_component comp;
        
        `uvm_info(get_type_name(), "===== Component Hierarchy =====", 
                 UVM_LOW)
        reset();
        while (has_next()) begin
            comp = get_next();
            `uvm_info(get_type_name(), comp.get_full_name(), UVM_LOW)
        end
    endfunction
endclass

// ============================================================================
// Part 6: UVM Component Using Iterator Pattern
// ============================================================================
class uvm_collector_with_iterator extends uvm_component;
    `uvm_component_utils(uvm_collector_with_iterator)
    
    transaction_collection collected_transactions;
    uvm_analysis_port #(uvm_transaction_example) item_collected_port;
    
    int unsigned num_items_collected = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
        collected_transactions = new("collected_transactions");
    endfunction
    
    function void write(uvm_transaction_example item);
        item.timestamp = $time;
        collected_transactions.add(item);
        item_collected_port.write(item);
        num_items_collected++;
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        report_collected_transactions();
    endfunction
    
    task report_collected_transactions();
        queue_iterator #(uvm_transaction_example) iter;
        uvm_transaction_example txn;
        int count = 0;
        
        `uvm_info(get_type_name(), 
                 "============ Collected Transactions ============", 
                 UVM_LOW)
        
        iter = collected_transactions.create_iterator();
        
        while (iter.has_next()) begin
            txn = iter.get_next();
            `uvm_info(get_type_name(), 
                     $sformatf("[%0d] %s", count++, txn.convert2string()), 
                     UVM_MEDIUM)
        end
        
        `uvm_info(get_type_name(), 
                 $sformatf("Total: %0d transactions collected", 
                          num_items_collected), UVM_LOW)
    endtask
endclass

// ============================================================================
// Part 7: Analysis Observer Using Iterator Pattern
// ============================================================================
class transaction_analyzer extends uvm_subscriber #(uvm_transaction_example);
    `uvm_component_utils(transaction_analyzer)
    
    transaction_collection all_transactions;
    transaction_collection read_transactions;
    transaction_collection write_transactions;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        all_transactions = new("all_transactions");
        read_transactions = new("read_transactions");
        write_transactions = new("write_transactions");
    endfunction
    
    function void write(uvm_transaction_example item);
        uvm_transaction_example cloned_item;
        
        $cast(cloned_item, item.clone());
        all_transactions.add(cloned_item);
        
        // Categorize transactions
        if (cloned_item.opcode[0] == 0)
            read_transactions.add(cloned_item);
        else
            write_transactions.add(cloned_item);
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), 
                 "========== Transaction Analysis Report ==========", 
                 UVM_LOW)
        
        report_transactions("All Transactions", all_transactions);
        report_transactions("Read Transactions", read_transactions);
        report_transactions("Write Transactions", write_transactions);
        
        analyze_patterns();
    endfunction
    
    task report_transactions(string title, transaction_collection coll);
        queue_iterator #(uvm_transaction_example) iter;
        uvm_transaction_example txn;
        int count = 0;
        
        `uvm_info(get_type_name(), $sformatf("--- %s ---", title), UVM_LOW)
        
        iter = coll.create_iterator();
        while (iter.has_next()) begin
            txn = iter.get_next();
            `uvm_info(get_type_name(), 
                     $sformatf("[%0d] %s", count++, txn.convert2string()), 
                     UVM_MEDIUM)
        end
        
        `uvm_info(get_type_name(), 
                 $sformatf("Count: %0d", coll.get_size()), UVM_LOW)
    endtask
    
    task analyze_patterns();
        queue_iterator #(uvm_transaction_example) iter;
        uvm_transaction_example txn_curr, txn_next;
        bit first = 1;
        
        `uvm_info(get_type_name(), "--- Address Access Patterns ---", UVM_LOW)
        
        iter = all_transactions.create_iterator();
        if (iter.has_next()) begin
            txn_curr = iter.get_next();
            while (iter.has_next()) begin
                txn_next = iter.get_next();
                
                if (txn_next.address == txn_curr.address + 4) begin
                    `uvm_info(get_type_name(), 
                             "Sequential access detected", UVM_MEDIUM)
                end
                
                txn_curr = txn_next;
            end
        end
    endtask
endclass

// ============================================================================
// Part 8: Test/Usage Example
// ============================================================================
module test_uvm_iterator_patterns;
    initial begin
        uvm_transaction_example txn;
        transaction_collection coll;
        queue_iterator #(uvm_transaction_example) forward_iter;
        reverse_iterator #(uvm_transaction_example) reverse_iter;
        int i;
        
        $display("\n========== Iterator Pattern with UVM ==========\n");
        
        // Create collection and add transactions
        coll = new("test_collection");
        
        for (i = 0; i < 5; i++) begin
            txn = new();
            txn.opcode = i[7:0];
            txn.address = (i * 4);
            txn.data = (i * 100);
            coll.add(txn);
        end
        
        // Forward iteration
        $display("\n--- Forward Iteration ---");
        forward_iter = coll.create_iterator();
        i = 0;
        while (forward_iter.has_next()) begin
            txn = forward_iter.get_next();
            $display("[%0d] %s", i++, txn.convert2string());
        end
        
        // Reverse iteration
        $display("\n--- Reverse Iteration ---");
        reverse_iter = coll.create_reverse_iterator();
        i = 0;
        while (reverse_iter.has_next()) begin
            txn = reverse_iter.get_next();
            $display("[%0d] %s", i++, txn.convert2string());
        end
        
        // Collection info
        $display("\nCollection Size: %0d", coll.get_size());
        
        $finish;
    end
endmodule

`endif // UVM_ITERATOR_PATTERNS_SV

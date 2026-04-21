/* 
 * This code demonstrates a composition-based solution to the "is-a" problem in UVM.
 * Instead of using inheritance to create a complex transaction class that "is-a" type of transaction with all features, 
 * we use composition to create a flexible transaction that "has-a" set of features. 
 * This allows us to enable or disable features dynamically without creating a large inheritance hierarchy.
 */ 

module tb(); 
import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum bit [1:0] {
    WRITE_THROUGH = 2'b00,    // Write to cache and memory simultaneously
    WRITE_BACK    = 2'b01,    // Write only to cache, memory later
    WRITE_AROUND  = 2'b10,    // Bypass cache for writes
    NO_ALLOCATE   = 2'b11     // Don't allocate on cache miss
} cache_policy_t;

// ============ FEATURE CLASSES (Composition) ============
class tag_feature extends uvm_sequence_item;
rand int tag;
rand bit tag_enabled = 0;

`uvm_object_utils_begin(tag_feature)
    `uvm_field_int(tag, UVM_ALL_ON)
    `uvm_field_int(tag_enabled, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "tag_feature");
    super.new(name);
endfunction
endclass

class cache_feature extends uvm_sequence_item;
rand bit cacheable = 0;
rand cache_policy_t policy;

`uvm_object_utils_begin(cache_feature)
    `uvm_field_int(cacheable, UVM_ALL_ON)
    `uvm_field_enum(cache_policy_t, policy, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "cache_feature");
    super.new(name);
endfunction
endclass

class priority_feature extends uvm_sequence_item;
rand int priority_c;
rand bit priority_enabled = 0;

`uvm_object_utils_begin(priority_feature)
    `uvm_field_int(priority_c, UVM_ALL_ON)
    `uvm_field_int(priority_enabled, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "priority_feature");
    super.new(name);
endfunction
endclass

// ============ CONFIGURATION CLASS (Builder Pattern) ============
class transaction_config extends uvm_sequence_item;
bit enable_tag = 0;
bit enable_cache = 0;
bit enable_priority = 0;

`uvm_object_utils_begin(transaction_config)
    `uvm_field_int(enable_tag, UVM_ALL_ON)
    `uvm_field_int(enable_cache, UVM_ALL_ON)
    `uvm_field_int(enable_priority, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "transaction_config");
    super.new(name);
endfunction
endclass

// ============ COMPOSITE TRANSACTION (Builder Pattern) ============
class composite_transaction extends uvm_sequence_item;
// Base attributes
rand int addr;
rand int data;

// Features as object handles (Composition - "has-a" not "is-a")
tag_feature      tag_f;
cache_feature    cache_f;
priority_feature prio_f;

// Configuration (Builder pattern)
transaction_config cfg;

`uvm_object_utils_begin(composite_transaction)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_object(tag_f, UVM_ALL_ON)
    `uvm_field_object(cache_f, UVM_ALL_ON)
    `uvm_field_object(prio_f, UVM_ALL_ON)
    `uvm_field_object(cfg, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "composite_transaction");
    super.new(name);
    // Initialize feature objects
    tag_f = tag_feature::type_id::create("tag_f");
    cache_f = cache_feature::type_id::create("cache_f");
    prio_f = priority_feature::type_id::create("prio_f");
    cfg = transaction_config::type_id::create("cfg");
endfunction

// Builder pattern: Configure before randomize
function void pre_randomize();
    // Apply configuration to enable/disable features
    tag_f.tag_enabled = cfg.enable_tag;
    cache_f.cacheable = cfg.enable_cache;
    prio_f.priority_enabled = cfg.enable_priority;
    
    // If feature disabled, don't randomize it
    if (!cfg.enable_tag) tag_f.tag.rand_mode(0);
    if (!cfg.enable_cache) cache_f.cacheable.rand_mode(0);
    if (!cfg.enable_priority) prio_f.priority_c.rand_mode(0);
endfunction

// Builder pattern: Post-process after randomize
function void post_randomize();
    // Clear disabled feature values
    if (!cfg.enable_tag) tag_f.tag = 0;
    if (!cfg.enable_priority) prio_f.priority_c = 0;
endfunction

// Helper methods
function bit has_tag();
    return cfg.enable_tag && tag_f.tag_enabled;
endfunction

function bit is_cacheable();
    return cfg.enable_cache && cache_f.cacheable;
endfunction

function int get_priority();
    return (cfg.enable_priority && prio_f.priority_enabled) ? prio_f.priority_c : 0;
endfunction
endclass

// ============ USAGE EXAMPLES ============
class test_scenarios extends uvm_test;
 `uvm_component_utils(test_scenarios)

function new(string name, uvm_component parent); 
        super.new(name,parent); 
endfunction // new 
task run_phase(uvm_phase phase);
    composite_transaction tr;
    transaction_config cfg;
    
    // ============ SCENARIO 1: Cached but NOT tagged ============
    `uvm_info("TEST", "Scenario 1: Cached but NOT tagged", UVM_LOW)
    tr = composite_transaction::type_id::create("tr");
    cfg = transaction_config::type_id::create("cfg");
    cfg.enable_cache = 1;      // Enable cache
    cfg.enable_tag = 0;        // Disable tag
    cfg.enable_priority = 0;   // Disable priority
    tr.cfg = cfg;
    
    if(tr.randomize()) begin 
        `uvm_info(get_type_name(),$sformatf("Randmozed Cache Transaction = %p",tr),UVM_LOW)
    end

    // cacheable=true, tag=disabled
    
    // ============ SCENARIO 2: Priority but NOT cacheable ============
    `uvm_info("TEST", "Scenario 2: Priority but NOT cacheable", UVM_LOW)
    tr = composite_transaction::type_id::create("tr");
    cfg = transaction_config::type_id::create("cfg");
    cfg.enable_priority = 1;   // Enable priority
    cfg.enable_cache = 0;      // Disable cache
    cfg.enable_tag = 0;        // Disable tag
    tr.cfg = cfg;
    
    if(tr.randomize()) begin 
        `uvm_info(get_type_name(),$sformatf("Randmozed Priority Transaction = %p",tr),UVM_LOW)
    end

    //  priority enabled, cacheable=false
    
    // ============ SCENARIO 3: Tagged + Priority but NOT cached ============
    `uvm_info("TEST", "Scenario 3: Tagged+Priority but NOT cached", UVM_LOW)
    tr = composite_transaction::type_id::create("tr");
    cfg = transaction_config::type_id::create("cfg");
    cfg.enable_tag = 1;        // Enable tag
    cfg.enable_priority = 1;   // Enable priority
    cfg.enable_cache = 0;      // Disable cache
    tr.cfg = cfg;
     
    if(tr.randomize()) begin 
        `uvm_info(get_type_name(),$sformatf("Randmozed Cache Priority Enabled Transaction = %p",tr),UVM_LOW)
    end

    //  tag enabled, priority enabled, cacheable=false
    
    // ============ SCENARIO 4: All features enabled ============
    `uvm_info("TEST", "Scenario 4: All features enabled", UVM_LOW)
    tr = composite_transaction::type_id::create("tr",this);
    cfg = transaction_config::type_id::create("cfg",this);
    cfg.enable_tag = 1;
    cfg.enable_cache = 1;
    cfg.enable_priority = 1;
    tr.cfg = cfg;
    
    if(tr.randomize()) begin 
        `uvm_info(get_type_name(),$sformatf("Randmozed All Features  Enabled Transaction = %p",tr),UVM_LOW)
    end
    
    //  all features active
    
    // ============ SCENARIO 5: Dynamic reconfiguration ============
    `uvm_info("TEST", "Scenario 5: Dynamic reconfiguration", UVM_LOW)
    tr = composite_transaction::type_id::create("tr");
    
    // Test with tags only
    tr.cfg.enable_tag = 1;
    tr.cfg.enable_cache = 0;
    tr.cfg.enable_priority = 0;
    assert(tr.randomize());
    
    // Now enable cache for same transaction instance
    tr.cfg.enable_cache = 1;
    assert(tr.randomize());
    // Same object, different feature set!
endtask
endclass

initial
begin 
    run_test("test_scenarios"); 
end


endmodule // tb. 
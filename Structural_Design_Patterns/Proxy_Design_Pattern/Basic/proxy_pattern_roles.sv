/*
    Proxy Design Pattern - Demonstrating Different Roles
    =====================================================
    
    The Proxy pattern provides a surrogate or placeholder for another object to control 
    access to it. This example shows the key roles:
    
    1. Subject/Interface - Defines the common interface
    2. RealSubject - The actual object that performs work
    3. Proxy - Controls access to the RealSubject
    4. Client - Uses the proxy without knowing about RealSubject
    
    This example demonstrates THREE types of proxies:
    - PROTECTION PROXY: Controls access based on permissions
    - VIRTUAL PROXY: Lazy initialization of expensive resources
    - LOGGING PROXY: Tracks all operations
*/

module tb();

`include "uvm_macros.svh"
import uvm_pkg::*;

// ============================================================================
// SUBJECT - Interface that both RealSubject and Proxy implement
// ============================================================================
virtual class memory_access_subject;
  // Define the interface that client will use
  pure virtual function bit [31:0] read(bit [31:0] address);
  pure virtual function void write(bit [31:0] address, bit [31:0] data);
  pure virtual function void display_status();
endclass

// ============================================================================
// REAL SUBJECT - The actual memory that performs real work
// ============================================================================
class real_memory extends memory_access_subject;
  local bit [31:0] memory[bit [31:0]];  // Simulated memory storage
  
  function new();
    `uvm_info("REAL_MEMORY", "Real Memory Object Created (Expensive Operation)", UVM_HIGH)
  endfunction
  
  // Real implementation of read
  function bit [31:0] read(bit [31:0] address);
    bit [31:0] data;
    data = memory[address];
    `uvm_info("REAL_MEMORY", $sformatf("Reading address %h -> data %h", address, data), UVM_MEDIUM)
    return data;
  endfunction
  
  // Real implementation of write
  function void write(bit [31:0] address, bit [31:0] data);
    memory[address] = data;
    `uvm_info("REAL_MEMORY", $sformatf("Writing to address %h <- data %h", address, data), UVM_MEDIUM)
  endfunction
  
  // Real implementation of status display
  function void display_status();
    $display("REAL_MEMORY: %0d memory locations used", memory.size());
  endfunction
endclass

// ============================================================================
// PROTECTION PROXY - Controls access based on user permissions
// ============================================================================
class protection_proxy extends memory_access_subject;
  protected memory_access_subject real_subject;
  protected int user_privilege_level;  // 0=Guest, 1=User, 2=Admin
  protected bit [31:0] protected_address_start = 32'h8000_0000;
  protected bit [31:0] protected_address_end   = 32'h9000_0000;
  
  function new(int privilege_level = 0);
    real_memory  real_memory;
    real_memory = new();
    user_privilege_level = privilege_level;
    real_subject = real_memory;
    `uvm_info("PROTECTION_PROXY", 
      $sformatf("Protection Proxy Created with privilege level %0d", privilege_level), UVM_HIGH)
  endfunction
  
  // Check if user has permission to access address
  local function bit has_permission(bit [31:0] address);
    // Admin (level 2) can access all addresses
    if (user_privilege_level == 2) return 1'b1;
    
    // Regular user (level 1) cannot access protected region
    if (user_privilege_level == 1) begin
      if (address >= protected_address_start && address <= protected_address_end) begin
        return 1'b0;  // Access denied
      end
      return 1'b1;
    end
    
    // Guest (level 0) has very limited access
    return 1'b0;
  endfunction
  
  function bit [31:0] read(bit [31:0] address);
    if (!has_permission(address)) begin
      `uvm_warning("PROTECTION_PROXY", 
        $sformatf("Access DENIED: User privilege %0d cannot read address %h", 
          user_privilege_level, address))
      return 32'hDEAD_BEEF;  // Return error pattern
    end
    `uvm_info("PROTECTION_PROXY", 
      $sformatf("Access GRANTED: Reading address %h (Privilege: %0d)", address, user_privilege_level), UVM_MEDIUM)
    return real_subject.read(address);
  endfunction
  
  function void write(bit [31:0] address, bit [31:0] data);
    if (!has_permission(address)) begin
      `uvm_warning("PROTECTION_PROXY", 
        $sformatf("Access DENIED: User privilege %0d cannot write address %h", 
          user_privilege_level, address))
      return;
    end
    `uvm_info("PROTECTION_PROXY", 
      $sformatf("Access GRANTED: Writing to address %h (Privilege: %0d)", address, user_privilege_level), UVM_MEDIUM)
    real_subject.write(address, data);
  endfunction
  
  function void display_status();
    $display("PROTECTION_PROXY: User Privilege Level = %0d", user_privilege_level);
    real_subject.display_status();
  endfunction
endclass

// ============================================================================
// VIRTUAL PROXY - Lazy initialization of expensive resources
// ============================================================================
class virtual_proxy extends memory_access_subject;
  protected memory_access_subject real_subject;  // Initialized only when needed
  protected bit is_initialized = 1'b0;
  protected int access_count = 0;
  
  function new();
    `uvm_info("VIRTUAL_PROXY", "Virtual Proxy Created (Real Subject NOT created yet)", UVM_HIGH)
  endfunction
  
  // Lazy initialization - create real subject only on first access
  local function void ensure_initialized();
    real_memory  real_memory;
    real_memory = new();
    if (!is_initialized) begin
      `uvm_info("VIRTUAL_PROXY", "Lazy Initialization: Creating Real Subject on first access", UVM_HIGH)
      real_subject = real_memory;
      is_initialized = 1'b1;
    end
  endfunction
  
  function bit [31:0] read(bit [31:0] address);
    access_count++;
    ensure_initialized();
    `uvm_info("VIRTUAL_PROXY", 
      $sformatf("Read Access #%0d to address %h", access_count, address), UVM_MEDIUM)
    return real_subject.read(address);
  endfunction
  
  function void write(bit [31:0] address, bit [31:0] data);
    access_count++;
    ensure_initialized();
    `uvm_info("VIRTUAL_PROXY", 
      $sformatf("Write Access #%0d to address %h", access_count, address), UVM_MEDIUM)
    real_subject.write(address, data);
  endfunction
  
  function void display_status();
    if (is_initialized) begin
      $display("VIRTUAL_PROXY: Real Subject initialized after %0d accesses", access_count);
      real_subject.display_status();
    end else begin
      $display("VIRTUAL_PROXY: Real Subject NOT yet initialized (0 accesses)");
    end
  endfunction
endclass

// ============================================================================
// LOGGING PROXY - Tracks all operations on the real subject
// ============================================================================
class logging_proxy extends memory_access_subject;
  protected memory_access_subject real_subject;
  protected int operation_log[$];  // Log of operations
  
  function new();
   // real_memory  real_memory; 
   // real_memory = new();
    `uvm_info("LOGGING_PROXY", "Logging Proxy Created with Real Memory", UVM_HIGH)
  endfunction
  
  function bit [31:0] read(bit [31:0] address);
    bit [31:0] data;
    operation_log.push_back(address);  // Log the address
    `uvm_info("LOGGING_PROXY", 
      $sformatf("LOGGED: Read operation #%0d on address %h", operation_log.size(), address), UVM_MEDIUM)
    data = real_subject.read(address);
    return data;
  endfunction
  
  function void write(bit [31:0] address, bit [31:0] data);
    operation_log.push_back(address);  // Log the address
    `uvm_info("LOGGING_PROXY", 
      $sformatf("LOGGED: Write operation #%0d on address %h with data %h", operation_log.size(), address, data), UVM_MEDIUM)
    real_subject.write(address, data);
  endfunction
  
  function void display_status();
    $display("LOGGING_PROXY: Total operations logged = %0d", operation_log.size());
    $display("LOGGING_PROXY: Operation addresses: %p", operation_log);
    real_subject.display_status();
  endfunction
endclass

// ============================================================================
// TEST - Client code that uses the proxies
// ============================================================================
class proxy_pattern_test extends uvm_test;
  `uvm_component_utils(proxy_pattern_test)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    memory_access_subject mem;
    bit [31:0] read_data;
    
    phase.raise_objection(this);
    
    $display("\n========== TEST 1: PROTECTION PROXY ==========\n");
    test_protection_proxy();
    
    $display("\n========== TEST 2: VIRTUAL PROXY ==========\n");
    test_virtual_proxy();
    
    $display("\n========== TEST 3: LOGGING PROXY ==========\n");
    test_logging_proxy();
    
    phase.drop_objection(this);
  endtask
  
  // ==================== Test Protection Proxy ====================
  task test_protection_proxy();
    memory_access_subject guest_memory, user_memory, admin_memory;
    protection_proxy  protection_proxy;
    bit [31:0] normal_addr = 32'h1000_0000;    // Normal memory
    bit [31:0] protected_addr = 32'h8500_0000; // Protected memory
    
    // Guest user (privilege = 0)
    $display("--- Guest User Access (Privilege Level 0) ---");
    guest_memory = new(); 
    
    protection_proxy = new(0);  // Create proxy with guest privileges
    guest_memory = protection_proxy;
    guest_memory.write(normal_addr, 32'hAAAA_AAAA);  // Attempt write
    guest_memory.read(normal_addr);                   // Attempt read
    
    // Regular user (privilege = 1)
    $display("\n--- Regular User Access (Privilege Level 1) ---");
    user_memory = new(); 
    protection_proxy = new(1);  // Create proxy with user privileges
    user_memory =  protection_proxy;
    user_memory.write(normal_addr, 32'hBBBB_BBBB);   // Success
    user_memory.read(normal_addr);                    // Success
    user_memory.write(protected_addr, 32'hCCCC_CCCC); // Denied
    user_memory.read(protected_addr);                 // Denied
    
    // Admin user (privilege = 2)
    $display("\n--- Admin User Access (Privilege Level 2) ---");
    admin_memory = new(); 
    protection_proxy = new(2);  // Create proxy with admin privileges
    admin_memory =  protection_proxy;
    admin_memory.write(protected_addr, 32'hDDDD_DDDD); // Success
    admin_memory.read(protected_addr);                 // Success
    admin_memory.display_status();
  endtask
  
  // ==================== Test Virtual Proxy ====================
  task test_virtual_proxy();
    memory_access_subject mem;
    virtual_proxy  virtual_proxy;
    
    $display("--- Creating Virtual Proxy (Real Subject NOT created) ---");
    mem = new(); 
    virtual_proxy = new();
    mem =  virtual_proxy;
    mem.display_status();
    
    $display("\n--- First Access: Triggers Lazy Initialization ---");
    mem.write(32'h2000_0000, 32'h1111_1111);
    mem.display_status();
    
    $display("\n--- Subsequent Accesses: Real Subject Already Exists ---");
    mem.read(32'h2000_0000);
    mem.write(32'h3000_0000, 32'h2222_2222);
    mem.display_status();
  endtask
  
  // ==================== Test Logging Proxy ====================
  task test_logging_proxy();
    memory_access_subject mem;
    logging_proxy  logging_proxy;
    $display("--- Creating Logging Proxy ---");
    mem = new(); 
    logging_proxy = new();
    mem =    logging_proxy;
    
    $display("\n--- Performing Operations (All Will Be Logged) ---");
    mem.write(32'h4000_0000, 32'hAAAA_1111);
    mem.read(32'h4000_0000);
    mem.write(32'h5000_0000, 32'hBBBB_2222);
    mem.read(32'h4000_0000);  // Read same address again
    mem.write(32'h6000_0000, 32'hCCCC_3333);
    
    $display("\n--- Operation Log Summary ---");
    mem.display_status();
  endtask
endclass

// ============================================================================
// MODULE - Test Instantiation
// ============================================================================
  initial begin
    run_test("proxy_pattern_test");
  end
endmodule // tb

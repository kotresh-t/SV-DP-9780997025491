// State Design Pattern for Traffic Light Controller - UVM Implementation
// Based on State Design Pattern Example
// 
// Key Concepts:
// - context_m: TrafficLightController (holds current state)
// - State: Abstract interface (tl_state_uvm) 
// - ConcreteState: Specific light colors (NORTH, NORTH_Y, SOUTH, etc.)
// - State transitions managed by states calling context_m methods



// Abstract state base class
class tl_state_uvm;
  string state_name;
  
  function new(string name = "");
    state_name = name;
  endfunction
  
  function string get_state_name();
    return state_name;
  endfunction
  
  // Abstract methods for state transitions
  virtual function void handle_tick(tl_context_uvm context_m);
  endfunction
  
  // Expected outputs for this state
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'bxxx; s = 3'bxxx; e = 3'bxxx; w = 3'bxxx;
  endfunction
endclass

// ============================================================
// Concrete State Classes
// ============================================================

class tl_north_uvm extends tl_state_uvm;
  function new(string name = "NORTH");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_north_y_uvm north_y_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 11) begin
      context_m.set_counter(0);
      north_y_state = new("NORTH_Y");
      context_m.set_state(north_y_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b001; s = 3'b100; e = 3'b100; w = 3'b100;  // Green for North, Red for others
  endfunction
endclass

class tl_north_y_uvm extends tl_state_uvm;
  function new(string name = "NORTH_Y");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_south_uvm south_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 4) begin
      context_m.set_counter(0);
      south_state = new();
      context_m.set_state(south_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b010; s = 3'b100; e = 3'b100; w = 3'b100;  // Yellow for North, Red for others
  endfunction
endclass

class tl_south_uvm extends tl_state_uvm;
  function new(string name = "SOUTH");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_south_y_uvm south_y_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 11) begin
      context_m.set_counter(0);
      south_y_state = new();
      context_m.set_state(south_y_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b001; e = 3'b100; w = 3'b100;  // Green for South, Red for others
  endfunction
endclass

class tl_south_y_uvm extends tl_state_uvm;
  function new(string name = "SOUTH_Y");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_east_uvm east_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 11) begin
      context_m.set_counter(0);
      east_state = new();
      context_m.set_state(east_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b010; e = 3'b100; w = 3'b100;  // Yellow for South, Red for others
  endfunction
endclass

class tl_east_uvm extends tl_state_uvm;
  function new(string name = "EAST");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_east_y_uvm east_y_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 7) begin
      context_m.set_counter(0);
      east_y_state = new();
      context_m.set_state(east_y_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b100; e = 3'b001; w = 3'b100;  // Green for East, Red for others
  endfunction
endclass

class tl_east_y_uvm extends tl_state_uvm;
  function new(string name = "EAST_Y");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_west_uvm west_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 11) begin
      context_m.set_counter(0);
      west_state = new();
      context_m.set_state(west_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b100; e = 3'b010; w = 3'b100;  // Yellow for East, Red for others
  endfunction
endclass

class tl_west_uvm extends tl_state_uvm;
  function new(string name = "WEST");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_west_y_uvm west_y_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 3) begin
      context_m.set_counter(0);
      west_y_state = new();
      context_m.set_state(west_y_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b100; e = 3'b100; w = 3'b001;  // Green for West, Red for others
  endfunction
endclass

class tl_west_y_uvm extends tl_state_uvm;
  function new(string name = "WEST_Y");
    super.new(name);
  endfunction
  
  virtual function void handle_tick(tl_context_uvm context_m);
    tl_north_uvm north_state;
    context_m.increment_counter();
    if (context_m.get_counter() >= 3) begin
      context_m.set_counter(0);
      north_state = new();  // Cycle back to NORTH
      context_m.set_state(north_state);
    end
  endfunction
  
  virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    n = 3'b100; s = 3'b100; e = 3'b100; w = 3'b010;  // Yellow for West, Red for others
  endfunction
endclass

// ============================================================
// context_m Class - Manages state transitions and current state
// ============================================================

class tl_context_uvm;
  protected tl_state_uvm current_state;
  protected int unsigned cycle_counter;
  
  function new();
    tl_north_uvm north_state;
    north_state = new();
    current_state = north_state;
    cycle_counter = 0;
  endfunction
  
  // Set the current state (called by state classes)
  function void set_state(tl_state_uvm new_state);
    $display("[STATE_TRANSITION] Changing from %s to %s", 
             current_state.get_state_name(), 
             new_state.get_state_name());
    current_state = new_state;
  endfunction
  
  // Get current state
  function tl_state_uvm get_state();
    return current_state;
  endfunction
  
  function string get_state_name();
    return current_state.get_state_name();
  endfunction
  
  // Counter management
  function void increment_counter();
    cycle_counter++;
  endfunction
  
  function void set_counter(int unsigned val);
    cycle_counter = val;
  endfunction
  
  function int unsigned get_counter();
    return cycle_counter;
  endfunction
  
  // Process a clock tick - delegates to current state
  function void tick();
    current_state.handle_tick(this);
  endfunction
  
  // Get expected outputs from current state
  function void get_expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    current_state.expected_outputs(n, s, e, w);
  endfunction
endclass
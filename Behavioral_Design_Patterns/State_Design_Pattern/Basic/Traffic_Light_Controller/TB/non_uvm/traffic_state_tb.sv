`timescale 1ns/1ps

// Non-UVM verification using the State Design Pattern
// - Implements State classes for the Traffic Light Controller
// - Drives clk/rst, samples outputs and compares expected state/outputs

module traffic_state_tb();

  // DUT signals
  reg clk;
  reg rst_a;
  wire [2:0] n_lights, s_lights, e_lights, w_lights;

  // instantiate DUT
  traffic_control dut(
    .n_lights(n_lights),
    .s_lights(s_lights),
    .e_lights(e_lights),
    .w_lights(w_lights),
    .clk(clk),
    .rst_a(rst_a)
  );

  // clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz for faster simulation (original TB used #10)
  end

  typedef class S_north_y; 
  typedef class S_south_y; 
  typedef class S_east_y; 
  typedef class S_west_y; 
  typedef class S_north; 
  typedef class S_south; 
  typedef class S_east; 
  typedef class S_west;     

  // ---------- State Design Pattern classes (test-side) ----------
  class tl_state;
    // name used for messages
    string name;
    function new(string n = ""); name = n; endfunction

    // called on each tick; returns next state handle (may be same)
    virtual function tl_state on_tick(ref int unsigned count);
      return this;
    endfunction

    // expected output encoding for this logical state
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'bxxx; s = 3'bxxx; e = 3'bxxx; w = 3'bxxx; // override in subclasses
    endfunction
  endclass

  // Concrete states (main and yellow for each direction)
  class S_north extends tl_state;
    function new(string name = "NORTH"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_north_y S_north_y; 

      if (count >= 8) begin
        count = 0;
        S_north_y = new("NORTH_Y"); 
        next_state = S_north_y;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b001; s = 3'b100; e = 3'b100; w = 3'b100;
    endfunction
  endclass

  class S_north_y extends tl_state;
    function new(string name = "NORTH_Y"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_south S_south;
      if (count == 3) begin
        count = 0;
        S_south = new("SOUTH");
        next_state = S_south;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b010; s = 3'b100; e = 3'b100; w = 3'b100;
    endfunction
  endclass

  class S_south extends tl_state;
    function new(string name = "SOUTH"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_south_y S_south_y;
      if (count == 7) begin
        count = 0;
        S_south_y = new("SOUTH_Y");
        next_state = S_south_y;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b001; e = 3'b100; w = 3'b100;
    endfunction
  endclass

  class S_south_y extends tl_state;
    function new(string name = "SOUTH_Y"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_east S_east;
      if (count == 3) begin
        count = 0;
        S_east = new("EAST");
        next_state = S_east;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b010; e = 3'b100; w = 3'b100;
    endfunction
  endclass

  class S_east extends tl_state;
    function new(string name = "EAST"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_east_y S_east_y;
      if (count == 7) begin
        count = 0;
        S_east_y = new("EAST_Y");
        next_state = S_east_y;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b100; e = 3'b001; w = 3'b100;
    endfunction
  endclass

  class S_east_y extends tl_state;
    function new(string name = "EAST_Y"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_west S_west;
      if (count == 3) begin
        count = 0;
        S_west = new("WEST");
        next_state = S_west;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b100; e = 3'b010; w = 3'b100;
    endfunction
  endclass

  class S_west extends tl_state;
    function new(string name = "WEST"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_west_y S_west_y;
      if (count == 7) begin
        count = 0;
        S_west_y = new("WEST_Y");
        next_state = S_west_y;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b100; e = 3'b100; w = 3'b001;
    endfunction
  endclass

  class S_west_y extends tl_state;
    function new(string name = "WEST_Y"); super.new(name); endfunction
    virtual function tl_state on_tick(ref int unsigned count);
      tl_state next_state;
      S_north S_north;
      if (count == 3) begin
        count = 0;
        S_north = new("NORTH");
        next_state = S_north;
        return next_state;
      end else begin
        count++;
        return this;
      end
    endfunction
    virtual function void expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      n = 3'b100; s = 3'b100; e = 3'b100; w = 3'b010;
    endfunction
  endclass

  // Context that holds current state and count (encapsulates state changes)
  class tl_context;
    tl_state current;
    S_north S_north;

    int unsigned count;
    function new();
      S_north = new(); 
      current = S_north;
      count = 0;
    endfunction

    function void tick();
      current = current.on_tick(count);
    endfunction

    function void get_expected_outputs(output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
      current.expected_outputs(n,s,e,w);
    endfunction

    function string get_state_name();
      return current.name;
    endfunction
  endclass

  // ---------- Test stimulus & self-check ----------
  tl_context ctx;
  integer cycles = 0;

  initial begin
   logic [2:0] exp_n, exp_s, exp_e, exp_w;
    // initialize
    rst_a = 1'b1;
    ctx = new();

    // hold reset for a few cycles
    repeat (3) @(posedge clk);
    rst_a = 1'b0;

    // check for two full cycles (48 cycles per full state cycle)
    for (cycles = 0; cycles < 100; cycles++) begin
      @(posedge clk);
      ctx.tick();

     
      ctx.get_expected_outputs(exp_n, exp_s, exp_e, exp_w);

      // compare DUT outputs with expected
      if (n_lights !== exp_n || s_lights !== exp_s || e_lights !== exp_e || w_lights !== exp_w) begin
        $display("[FAIL] cycle=%0d expected=%s n=%b s=%b e=%b w=%b  DUT n=%b s=%b e=%b w=%b",
          $time, ctx.get_state_name(), exp_n, exp_s, exp_e, exp_w, n_lights, s_lights, e_lights, w_lights);
        $fatal(1, "Mismatch detected — State pattern check failed");
      end else begin
        $display("[OK]  time=%0t state=%s n=%b s=%b e=%b w=%b", $time, ctx.get_state_name(), n_lights, s_lights, e_lights, w_lights);
      end
    end

    $display("Non-UVM State-pattern verification completed successfully.");
    $finish;
  end

endmodule
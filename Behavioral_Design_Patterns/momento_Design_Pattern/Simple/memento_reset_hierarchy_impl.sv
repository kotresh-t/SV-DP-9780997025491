module tb(); 

typedef enum {SOFT_RESET, MEDIUM_RESET, HARD_RESET} reset_t;

// 4.1 Memento – Immutable Snapshot
class reg_memento;

  // snapshot of register fields
  protected bit [31:0] field_values[string];

  function new(bit [31:0] snapshot[string]);
    foreach (snapshot[k])
      field_values[k] = snapshot[k];
  endfunction

  function bit [31:0] get(string field);
    return field_values[field];
  endfunction

endclass

// Originator – Register Model
class reg_model;

  // example fields
  bit [31:0] ctrl;
  bit [31:0] status;
  bit [31:0] cfg;

  // snapshot creation
  function reg_memento create_memento();
    reg_memento Memento_r; 
    bit [31:0] snap[string];
    snap["ctrl"]   = ctrl;
    snap["status"] = status;
    snap["cfg"]    = cfg;
    Memento_r = new(snap);
    return Memento_r; 
  endfunction

  // restore
  function void restore(reg_memento m);
    ctrl   = m.get("ctrl");
    status = m.get("status");
    cfg    = m.get("cfg");
  endfunction

  // reset behaviors
  function void soft_reset();
    status = '0;
  endfunction

  function void medium_reset();
    status = '0;
    cfg    = '0;
  endfunction

  function void hard_reset();
    ctrl   = '0;
    status = '0;
    cfg    = '0;
  endfunction

endclass


// CARETAKER – Scoreboard

class reg_scoreboard;

  // stack of snapshots (LIFO)
  protected reg_memento history[$];

  function void save_state(reg_model rm);
    history.push_back(rm.create_memento());
  endfunction

  function void restore_last(reg_model rm);
    if (history.size() > 0) begin
      rm.restore(history.pop_back());
    end
  endfunction

endclass

// CHAIN OF RESPONSIBILITY – Reset Propagation
// 1 : Reset Handler Base
virtual class reset_handler;

  protected reset_handler next;

  function void set_next(reset_handler n);
    next = n;
  endfunction

  virtual function void handle(reset_t r,
                               reg_model rm,
                               reg_scoreboard sb);
    if (next != null)
      next.handle(r, rm, sb);
  endfunction

endclass


// 6.2 Soft Reset Handler
class soft_reset_handler extends reset_handler;

  virtual function void handle(reset_t r,
                               reg_model rm,
                               reg_scoreboard sb);
    if (r == SOFT_RESET) begin
      sb.save_state(rm);
      rm.soft_reset();
    end else
      super.handle(r, rm, sb);
  endfunction

endclass

// 6.3 Medium Reset Handler
class medium_reset_handler extends reset_handler;

  virtual function void handle(reset_t r,
                               reg_model rm,
                               reg_scoreboard sb);
    if (r == MEDIUM_RESET) begin
      sb.save_state(rm);
      rm.medium_reset();
    end else
      super.handle(r, rm, sb);
  endfunction

endclass

// 6.4 Hard Reset Handler
class hard_reset_handler extends reset_handler;

  virtual function void handle(reset_t r,
                               reg_model rm,
                               reg_scoreboard sb);
    if (r == HARD_RESET) begin
      // Hard reset can restore state lost by softer resets
      rm.hard_reset();
      sb.restore_last(rm);
    end
  endfunction

endclass

// 7. Wiring the Chain
function reset_handler build_reset_chain();
  soft_reset_handler   soft_r   ; 
  medium_reset_handler medium_r  ;
  hard_reset_handler   hard_r   ; 

  soft_r = new(); 
  medium_r = new(); 
  hard_r  = new(); 

  soft_r.set_next(medium_r);
  medium_r.set_next(hard_r);

  return soft_r; // head of chain
endfunction

// . End-to-End Example (Testbench)

  reg_model        rm;
  reg_scoreboard   sb;
  reset_handler    chain;

  initial begin
    rm = new();
    sb = new();
    chain = build_reset_chain();

    // initialize registers
    rm.ctrl   = 32'hA;
    rm.status = 32'hB;
    rm.cfg    = 32'hC;

    // soft reset
    chain.handle(SOFT_RESET, rm, sb);
    $display("CTRL=%h STATUS=%h CFG=%h", rm.ctrl, rm.status, rm.cfg);

    // medium reset
    chain.handle(MEDIUM_RESET, rm, sb);
    $display("CTRL=%h STATUS=%h CFG=%h", rm.ctrl, rm.status, rm.cfg);

    // hard reset restores previous snapshot
    chain.handle(HARD_RESET, rm, sb);

    $display("CTRL=%h STATUS=%h CFG=%h", rm.ctrl, rm.status, rm.cfg);
  end

endmodule



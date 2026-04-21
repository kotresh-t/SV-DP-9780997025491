/* .. 
// FSM Context Save-Restore
// Finite-state machines snapshot transient states before interrupts or power events, restoring post-event for coverage.​
// UVM FSM models use Memento with State/Mediator patterns for accurate transition checking .
*/ 

module tb(); 

`include "uvm_macros.svh" 
import uvm_pkg::*; 

typedef enum {
  IDLE,
  DECODE,
  EXECUTE,
  WAIT,
  ERROR
} fsm_state_t;

class fsm_memento;

  protected fsm_state_t state;
  protected int unsigned cycle_count;

  function new(fsm_state_t s, int unsigned c);
    state       = s;
    cycle_count = c;
  endfunction

  function fsm_state_t get_state();
    return state;
  endfunction

  function int unsigned get_cycle();
    return cycle_count;
  endfunction

endclass


class fsm_model extends uvm_object;

  `uvm_object_utils(fsm_model)

  protected fsm_state_t current_state;
  protected int unsigned cycle_count;

  function new(string name = "fsm_model");
    super.new(name);
    current_state = IDLE;
    cycle_count   = 0;
  endfunction

  // ---------- MEMENTO ----------
  function fsm_memento create_memento();
    fsm_memento fsm_m; 
    fsm_m =  new(current_state, cycle_count);
    return fsm_m; 
  endfunction

  function void restore(fsm_memento m);
    current_state = m.get_state();
    cycle_count   = m.get_cycle();
  endfunction

  // ---------- FSM BEHAVIOR ----------
  function void step();
    cycle_count++;

    case (current_state)
      IDLE     : current_state = DECODE;
      DECODE   : current_state = EXECUTE;
      EXECUTE  : current_state = WAIT;
      WAIT     : current_state = IDLE;
      default  : current_state = ERROR;
    endcase
  endfunction

  function fsm_state_t get_state();
    return current_state;
  endfunction

endclass


class fsm_context_mgr extends uvm_object;

  `uvm_object_utils(fsm_context_mgr)

  protected fsm_memento saved_ctx;

  function new(string name="fsm_context_mgr"); 
    super.new(name) ;
  endfunction // new 
  function void save(fsm_model fsm);
    saved_ctx = fsm.create_memento();
  endfunction

  function void restore(fsm_model fsm);
    if (saved_ctx != null)
      fsm.restore(saved_ctx);
  endfunction

endclass

/* 
Mediator – Transition & Coverage Coordinator

The mediator ensures:

Valid transition checking

Coverage continuity across restore
*/ 

class fsm_mediator extends uvm_component;

  `uvm_component_utils(fsm_mediator)

  fsm_model        fsm;
  fsm_context_mgr  ctx_mgr;

  covergroup fsm_cg;
    state : coverpoint fsm.get_state();
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    fsm    = fsm_model::type_id::create("fsm");
    ctx_mgr = fsm_context_mgr::type_id::create("ctx_mgr");
    fsm_cg = new();
  endfunction

  // FSM execution
  task run_step();
    fsm.step();
    fsm_cg.sample();
  endtask

  // Interrupt handling
  task interrupt_event();
    ctx_mgr.save(fsm);
    `uvm_info("FSM", "Interrupt detected, state saved", UVM_MEDIUM)
  endtask

  task resume_after_interrupt();
    ctx_mgr.restore(fsm);
    `uvm_info("FSM", "FSM state restored after interrupt", UVM_MEDIUM)
  endtask

endclass

fsm_mediator med;

  initial begin
    med = new("med", null);

    med.run_step(); // IDLE → DECODE
    med.run_step(); // DECODE → EXECUTE

    // Interrupt occurs mid-execution
    med.interrupt_event();

    // FSM would normally reset here (power event)
    // Instead, restore context
    med.resume_after_interrupt();

    med.run_step(); // EXECUTE → WAIT
    med.run_step(); // WAIT → IDLE
  end


endmodule

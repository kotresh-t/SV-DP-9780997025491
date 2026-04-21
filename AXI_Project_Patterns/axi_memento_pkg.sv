package axi_memento_pkg;
  import uvm_pkg::*;

  typedef enum {IDLE, AW, W, B} axi_fsm_state_e;

  class axi_fsm_memento;
    axi_fsm_state_e state;
    int cycle_count;

    function new(axi_fsm_state_e s, int c);
      state = s;
      cycle_count = c;
    endfunction
  endclass

  class axi_fsm_model extends uvm_object;
    axi_fsm_state_e current_state = IDLE;
    int cycle_count = 0;

    function new(string name = "axi_fsm_model");
      super.new(name);
    endfunction

    function axi_fsm_memento save();
      axi_fsm_memento m;
      m = new(current_state, cycle_count);
      return m;
    endfunction

    task restore(axi_fsm_memento m);
      current_state = m.state;
      cycle_count = m.cycle_count;
    endtask

    task step();
      cycle_count++;
      case (current_state)
        IDLE: current_state = AW;
        AW:   current_state = W;
        W:    current_state = B;
        B:    current_state = IDLE;
      endcase
    endtask
  endclass
endpackage

package traffic_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // transaction mirrors the DUT outputs (used by monitor & scoreboard)
  class traffic_trans extends uvm_sequence_item;
    rand logic [2:0] n_lights, s_lights, e_lights, w_lights;
    `uvm_object_utils(traffic_trans)
    function new(string name = "traffic_trans"); super.new(name); endfunction
    function string convert2string();
      return $sformatf("n=%b s=%b e=%b w=%b", n_lights, s_lights, e_lights, w_lights);
    endfunction
  endclass

  // simple expected-state helper used by test to check outputs (State pattern representation)
  typedef enum {NORTH, NORTH_Y, SOUTH, SOUTH_Y, EAST, EAST_Y, WEST, WEST_Y} tl_state_e;

  // function that returns expected outputs for logical state
  function automatic void expected_for_state(tl_state_e st, output logic [2:0] n, output logic [2:0] s, output logic [2:0] e, output logic [2:0] w);
    case (st)
      NORTH:   begin n=3'b001; s=3'b100; e=3'b100; w=3'b100; end
      NORTH_Y: begin n=3'b010; s=3'b100; e=3'b100; w=3'b100; end
      SOUTH:   begin n=3'b100; s=3'b001; e=3'b100; w=3'b100; end
      SOUTH_Y: begin n=3'b100; s=3'b010; e=3'b100; w=3'b100; end
      EAST:    begin n=3'b100; s=3'b100; e=3'b001; w=3'b100; end
      EAST_Y:  begin n=3'b100; s=3'b100; e=3'b010; w=3'b100; end
      WEST:    begin n=3'b100; s=3'b100; e=3'b100; w=3'b001; end
      WEST_Y:  begin n=3'b100; s=3'b100; e=3'b100; w=3'b010; end
    endcase
  endfunction

endpackage : traffic_pkg
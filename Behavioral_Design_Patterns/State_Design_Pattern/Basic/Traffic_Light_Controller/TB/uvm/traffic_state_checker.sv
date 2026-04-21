import uvm_pkg::*;
`include "uvm_macros.svh"
import traffic_pkg::*;


class traffic_state_checker extends uvm_component;
  `uvm_component_utils(traffic_state_checker)

  uvm_analysis_imp#(traffic_trans, traffic_state_checker) analysis_export;
  tl_context_uvm ctx;
  int unsigned sample_count;
  int unsigned error_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    sample_count = 0;
    error_count = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ctx = new();
  endfunction

  // called by monitor via analysis_export
  function void write(traffic_trans t);
    logic [2:0] exp_n, exp_s, exp_e, exp_w;
    exp_n = 3'b000;
    exp_s = 3'b000; 
    exp_e = 3'b000;
    exp_w = 3'b000;     
    
    $display("KT_DEBUG:: Current State = %s",ctx.get_state_name());

    sample_count++;
    // Get expected outputs for CURRENT state before advancing
    ctx.get_expected_outputs(exp_n, exp_s, exp_e, exp_w);
    
    // Then advance state machine for next sample
    ctx.tick();

    if (t.n_lights !== exp_n || t.s_lights !== exp_s || t.e_lights !== exp_e || t.w_lights !== exp_w) begin
      error_count++;
      `uvm_error("STATE_CHK", $sformatf("Mismatch at sample %0d: expected %s n=%b s=%b e=%b w=%b  DUT %s",
        sample_count, ctx.get_state_name(), exp_n, exp_s, exp_e, exp_w, t.convert2string()))
    end else begin
      `uvm_info("STATE_CHK", $sformatf("OK sample %0d state=%s %s", sample_count, ctx.get_state_name(), t.convert2string()),UVM_DEBUG)
    end
  endfunction

  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info("STATE_CHK", $sformatf("Samples=%0d Errors=%0d", sample_count, error_count), UVM_LOW)
    if (error_count != 0) begin
      `uvm_error("STATE_CHK", $sformatf("State checker observed %0d mismatches", error_count))
    end
  endfunction

endclass
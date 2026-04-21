// PCIe LTSSM Testbench
// Demonstrates Root Complex and Endpoint LTSSM synchronization
// Tests Gen1, Gen2, and Gen3 link training scenarios

`timescale 1ns / 1ps

`include "ltssm_pkg.sv"

module ltssm_tb;

  import ltssm_pkg::*;

  // Simulation parameters
  parameter CLK_PERIOD = 10;    // 10ns clock = 100MHz
  parameter TEST_DURATION = 500; // 5000ns simulation

  // Signals
  logic clk;
  logic rst_n;
  
  // RC to EP/PHY interface
  logic ep_present_sig;
  logic ep_tx_ready_sig;
  logic rx_valid_sig;
  
  // EP from RC/PHY interface
  logic rc_active_sig;
  logic tx_sync_ok_sig;
  logic rx_training_seq_sig;
  logic equ_request_sig;
  
  // RC outputs
  logic rc_link_up;
  logic rc_link_training;
  logic [2:0] rc_state;
  logic [7:0] rc_speed_gt_s;
  logic [1:0] rc_gen_capability;
  logic [2:0] rc_state_count;
  logic rc_state_transition;
  
  // EP outputs
  logic ep_link_up;
  logic ep_link_training;
  logic [2:0] ep_state;
  logic [7:0] ep_speed_gt_s;
  logic [1:0] ep_gen_capability;
  logic [2:0] ep_state_count;
  logic ep_state_transition;
  logic ep_tx_ready;
  logic ep_equ_complete;

  // Instantiate RC LTSSM (Target Gen3)
  pcie_rc_ltssm #(
    .TARGET_GEN(3)
  ) rc_ltssm_inst (
    .clk(clk),
    .rst_n(rst_n),
    .ep_present(ep_present_sig),
    .ep_tx_ready(ep_tx_ready_sig),
    .rx_valid(rx_valid_sig),
    .link_up(rc_link_up),
    .link_training(rc_link_training),
    .current_state(rc_state),
    .speed_gt_s(rc_speed_gt_s),
    .gen_capability(rc_gen_capability),
    .state_count(rc_state_count),
    .state_transition(rc_state_transition)
  );

  // Instantiate EP LTSSM (Max Gen3)
  pcie_ep_ltssm #(
    .MAX_GEN(3)
  ) ep_ltssm_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rc_active(rc_active_sig),
    .tx_sync_ok(tx_sync_ok_sig),
    .rx_training_seq(rx_training_seq_sig),
    .equ_request(equ_request_sig),
    .link_up(ep_link_up),
    .link_training(ep_link_training),
    .current_state(ep_state),
    .speed_gt_s(ep_speed_gt_s),
    .gen_capability(ep_gen_capability),
    .tx_ready(ep_tx_ready),
    .equ_complete(ep_equ_complete),
    .state_count(ep_state_count),
    .state_transition(ep_state_transition)
  );

  // Clock generation
  always begin
    clk = 1'b0;
    #(CLK_PERIOD/2);
    clk = 1'b1;
    #(CLK_PERIOD/2);
  end

  // Test stimulus
  initial begin
    $display("\n========================================================");
    $display("  PCIe LTSSM Gen3 Link Training Simulation");
    $display("  Root Complex <-> Endpoint");
    $display("========================================================\n");

    // Reset
    rst_n = 1'b0;
    ep_present_sig = 1'b0;
    ep_tx_ready_sig = 1'b0;
    rx_valid_sig = 1'b0;
    rc_active_sig = 1'b0;
    tx_sync_ok_sig = 1'b0;
    rx_training_seq_sig = 1'b0;
    equ_request_sig = 1'b0;

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    
    $display("[TB] Reset released at time %0d ns\n", $time);

    // Scenario 1: Detect phase (Endpoint present detection)
    $display("[TB] >>> PHASE 1: DETECT <<<");
    repeat (10) @(posedge clk);
    
    // Endpoint presents itself
    ep_present_sig = 1'b1;
    rc_active_sig = 1'b1;
    $display("[TB] Endpoint detected by RC at time %0d ns", $time);
    
    repeat (10) @(posedge clk);

    // Scenario 2: Polling phase (Speed negotiation)
    $display("\n[TB] >>> PHASE 2: POLLING - Speed Negotiation <<<");
    ep_tx_ready_sig = 1'b1;
    tx_sync_ok_sig = 1'b1;
    $display("[TB] EP transmitter ready, RC initiating speed negotiation at time %0d ns", $time);
    
    repeat (20) @(posedge clk);

    // Scenario 3: Configuration phase
    $display("\n[TB] >>> PHASE 3: CONFIGURATION <<<");
    rx_training_seq_sig = 1'b1;
    rx_valid_sig = 1'b1;
    $display("[TB] Training sequences exchanged at time %0d ns", $time);
    $display("[TB] RC and EP configuring link...");
    
    repeat (25) @(posedge clk);

    // Scenario 4: Recovery phase (Gen3 equalization)
    $display("\n[TB] >>> PHASE 4: RECOVERY (Gen3 Equalization) <<<");
    equ_request_sig = 1'b1;
    $display("[TB] Equalization phase active at time %0d ns", $time);
    $display("[TB] RC and EP performing Gen3 link equalization...");
    
    repeat (20) @(posedge clk);

    // Scenario 5: L0 reached
    $display("\n[TB] >>> PHASE 5: L0 - LINK OPERATIONAL <<<");
    equ_request_sig = 1'b0;
    repeat (15) @(posedge clk);

    // Print final status
    $display("\n========================================================");
    $display("  FINAL LINK STATUS");
    $display("========================================================");
    $display("[RC] Link Up: %0b, Training: %0b", rc_link_up, rc_link_training);
    $display("[RC] State: %0d, Speed: %0d GT/s, Gen: %0d", 
      rc_state, rc_speed_gt_s, rc_gen_capability);
    $display("[EP] Link Up: %0b, Training: %0b", ep_link_up, ep_link_training);
    $display("[EP] State: %0d, Speed: %0d GT/s, Gen: %0d\n", 
      ep_state, ep_speed_gt_s, ep_gen_capability);

    // Keep signals stable for final period
    repeat (20) @(posedge clk);

    $display("========================================================");
    $display("  Simulation Complete");
    $display("========================================================\n");
    $finish;
  end

  // State name decode function for display
  function string get_state_name(logic [2:0] state);
    case (state)
      3'b000: return "DETECT";
      3'b001: return "POLLING";
      3'b010: return "CONFIGURATION";
      3'b011: return "RECOVERY";
      3'b100: return "L0";
      default: return "UNKNOWN";
    endcase
  endfunction

  // Monitor block to display state transitions
  always @(posedge clk) begin
    if (rst_n) begin
      // RC state transitions
      if (rc_state_transition) begin
        $display("[time %0t ns] RC State Transition: %s (Gen %0d @ %0d GT/s)", 
          $time, get_state_name(rc_state), rc_gen_capability, rc_speed_gt_s);
      end

      // EP state transitions
      if (ep_state_transition) begin
        $display("[time %0t ns] EP State Transition: %s (Gen %0d @ %0d GT/s)", 
          $time, get_state_name(ep_state), ep_gen_capability, ep_speed_gt_s);
      end

      // Check for synchronization
      if (rc_link_up && !ep_link_up) begin
        $warning("[time %0t ns] RC reached L0 but EP still training", $time);
      end
      if (ep_link_up && !rc_link_up) begin
        $warning("[time %0t ns] EP reached L0 but RC still training", $time);
      end

      // Success condition
      if (rc_link_up && ep_link_up) begin
        $display("\n[SUCCESS] Both RC and EP reached L0 - Link Training Complete!");
      end
    end
  end

  // Generate VCD waveform for debugging
  initial begin
    $dumpfile("ltssm_tb.vcd");
    $dumpvars(0, ltssm_tb);
  end

endmodule : ltssm_tb

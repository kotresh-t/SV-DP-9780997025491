// PCIe Root Complex (RC) LTSSM State Machine Implementation
// RC is the master that initiates and controls link training
// Monitors endpoint readiness and drives speed negotiation

`include "ltssm_pkg.sv"

module pcie_rc_ltssm #(
  parameter TARGET_GEN = 3  // Target generation: 1 (Gen1), 2 (Gen2), 3 (Gen3)
) (
  input  logic         clk,
  input  logic         rst_n,
  
  // Physical layer interface (from PHY/Endpoint)
  input  logic         ep_present,           // Endpoint detected on link
  input  logic         ep_tx_ready,          // Endpoint transmitter ready (TS1 received)
  input  logic         rx_valid,             // Received valid training sequence
  
  // Output status
  output logic         link_up,              // Link training complete, L0 reached
  output logic         link_training,       // Link in training (not yet L0)
  output logic [2:0]   current_state,       // Current LTSSM state
  output logic [7:0]   speed_gt_s,          // Negotiated speed in GT/s
  output logic [1:0]   gen_capability,      // Negotiated Gen (0=Gen1, 1=Gen2, 2=Gen3)
  
  // Debug signals
  output logic [2:0]   state_count,         // State machine cycle counter (mod 8 for visibility)
  output logic         state_transition     // Indicates state changed this cycle
);

  import ltssm_pkg::*;

  // LTSSM context
  ltssm_context rc_ltssm;
  
  // Internal signals
  ltssm_state_t     prev_state;
  ltssm_state_t     current_state_internal;
  ltssm_status_t    status;
  int unsigned      cycle_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ltssm_context rc_context;
      rc_context = new("RC");
      rc_ltssm = rc_context;
      prev_state = DETECT;
      cycle_count = 0;
      
      // Initialize outputs
      link_up = 1'b0;
      link_training = 1'b1;
      current_state = 3'b000; // DETECT
      speed_gt_s = 8'd25;     // Gen1 default
      gen_capability = 2'b00; // Gen1 default
      state_count = 3'b000;
      state_transition = 1'b0;
    end else begin
      // Update RC status based on inputs
      rc_ltssm.link_status.receiver_ready = ep_present;
      rc_ltssm.link_status.transmitter_ready = ep_tx_ready || rx_valid;
      
      // Set target generation based on parameter
      case (TARGET_GEN)
        1: rc_ltssm.link_status.target_gen = GEN1;
        2: rc_ltssm.link_status.target_gen = GEN2;
        3: rc_ltssm.link_status.target_gen = GEN3;
        default: rc_ltssm.link_status.target_gen = GEN1;
      endcase

      // Save previous state for transition detection
      prev_state = rc_ltssm.get_current_state();

      // Advance LTSSM state machine
      rc_ltssm.tick();

      // Detect state transition
      current_state_internal = rc_ltssm.get_current_state();
      state_transition = (current_state_internal != prev_state);

      // Get updated status
      status = rc_ltssm.get_status();

      // Output current state encoding
      case (current_state_internal)
        DETECT:        current_state = 3'b000;
        POLLING:       current_state = 3'b001;
        CONFIGURATION: current_state = 3'b010;
        RECOVERY:      current_state = 3'b011;
        L0:            current_state = 3'b100;
        default:       current_state = 3'b111;
      endcase

      // Output speed and generation
      case (status.negotiated_speed)
        SPEED_2_5: begin
          speed_gt_s = 8'd25;
          gen_capability = 2'b00;
        end
        SPEED_5_0: begin
          speed_gt_s = 8'd50;
          gen_capability = 2'b01;
        end
        SPEED_8_0: begin
          speed_gt_s = 8'd80;
          gen_capability = 2'b10;
        end
        default: begin
          speed_gt_s = 8'd25;
          gen_capability = 2'b00;
        end
      endcase

      // Link status outputs
      link_up = status.link_up;
      link_training = !status.link_up;

      // Cycle counter for visibility
      cycle_count++;
      state_count = cycle_count[2:0];
    end
  end

  // Continuous monitoring assertions
  always @(posedge clk) begin
    // Check: Gen3 link should attempt recovery for equalization
    if (rc_ltssm.get_current_state() == CONFIGURATION && 
        rc_ltssm.link_status.target_gen == GEN3) begin
      // This is normal behavior for Gen3
    end

    // Check: L0 state should have link_up asserted
    if (rc_ltssm.get_current_state() == L0) begin
      assert (link_up) else $warning("[RC] L0 reached but link_up not asserted");
    end
  end

endmodule : pcie_rc_ltssm

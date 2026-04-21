// PCIe Endpoint (EP) LTSSM State Machine Implementation
// EP is the slave that responds to RC-initiated link training
// Detects RC presence and follows speed negotiation

`include "ltssm_pkg.sv"

module pcie_ep_ltssm #(
  parameter MAX_GEN = 3  // Maximum supported generation: 1 (Gen1), 2 (Gen2), 3 (Gen3)
) (
  input  logic         clk,
  input  logic         rst_n,
  
  // Physical layer interface (from PHY/RC)
  input  logic         rc_active,           // RC detected on link (training initiated)
  input  logic         tx_sync_ok,          // Transmitter synchronization achieved
  input  logic         rx_training_seq,     // Received TS1/TS2 from RC
  input  logic         equ_request,         // Equalization requested (Gen3)
  
  // Output status
  output logic         link_up,             // Link training complete, L0 reached
  output logic         link_training,      // Link in training (not yet L0)
  output logic [2:0]   current_state,       // Current LTSSM state
  output logic [7:0]   speed_gt_s,          // Negotiated speed in GT/s
  output logic [1:0]   gen_capability,      // Negotiated Gen (0=Gen1, 1=Gen2, 2=Gen3)
  
  // EP transmit signals (to RC)
  output logic         tx_ready,            // EP transmitter ready (TS1)
  output logic         equ_complete,        // Equalization complete (Gen3)
  
  // Debug signals
  output logic [2:0]   state_count,         // State machine cycle counter (mod 8)
  output logic         state_transition     // Indicates state changed this cycle
);

  import ltssm_pkg::*;

  // LTSSM context
  ltssm_context ep_ltssm;
  
  // Internal signals
  ltssm_state_t     prev_state;
  ltssm_state_t     current_state_internal;
  ltssm_status_t    status;
  int unsigned      cycle_count;
  logic             equ_done;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ltssm_context ep_context;
      ep_context = new("EP");
      ep_ltssm = ep_context;
      prev_state = DETECT;
      cycle_count = 0;
      equ_done = 1'b0;
      
      // Initialize outputs
      link_up = 1'b0;
      link_training = 1'b1;
      current_state = 3'b000; // DETECT
      speed_gt_s = 8'd25;     // Gen1 default
      gen_capability = 2'b00; // Gen1 default
      tx_ready = 1'b0;
      equ_complete = 1'b0;
      state_count = 3'b000;
      state_transition = 1'b0;
    end else begin
      // Update EP status based on inputs from RC/PHY
      // EP detects RC activity instead of initiating
      ep_ltssm.link_status.receiver_ready = rc_active || rx_training_seq;
      ep_ltssm.link_status.transmitter_ready = tx_sync_ok;
      
      // Set maximum supported generation based on parameter
      case (MAX_GEN)
        1: ep_ltssm.link_status.target_gen = GEN1;
        2: ep_ltssm.link_status.target_gen = GEN2;
        3: ep_ltssm.link_status.target_gen = GEN3;
        default: ep_ltssm.link_status.target_gen = GEN1;
      endcase

      // Save previous state for transition detection
      prev_state = ep_ltssm.get_current_state();

      // Advance LTSSM state machine
      ep_ltssm.tick();

      // Detect state transition
      current_state_internal = ep_ltssm.get_current_state();
      state_transition = (current_state_internal != prev_state);

      // Get updated status
      status = ep_ltssm.get_status();

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

      // EP transmitter feedback to RC
      tx_ready = (current_state_internal >= POLLING) ? 1'b1 : 1'b0;

      // Equalization complete (Gen3 Recovery state indicates equalization)
      if (current_state_internal == RECOVERY) begin
        equ_done = 1'b1;
        equ_complete = 1'b1;
      end else if (current_state_internal == L0) begin
        equ_complete = 1'b0; // Equalization complete flag for one cycle
        equ_done = 1'b0;
      end

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
    // Check: EP should follow RC state transitions (with some delay)
    // No assertion enforced here, EP can lag behind RC by a few cycles

    // Check: L0 state should have link_up asserted
    if (ep_ltssm.get_current_state() == L0) begin
      assert (link_up) else $warning("[EP] L0 reached but link_up not asserted");
    end

    // Check: EP transmitter not ready until at least POLLING
    if (current_state_internal < POLLING) begin
      assert (!tx_ready) else $warning("[EP] TX ready before POLLING state");
    end
  end

endmodule : pcie_ep_ltssm

// PCIe LTSSM (Link Training and Status State Machine) Package
// Defines state classes and common types for PCIe Gen3 LTSSM model
// Models states: Detect -> Polling -> Configuration -> Recovery -> L0
// Supports Gen1/Gen2/Gen3 speed negotiation

package ltssm_pkg;

  // Gen3 LTSSM States (main states till L0)
  typedef enum {
    DETECT,         // Detect presence of device on the link
    POLLING,        // Speed negotiation and equalization
    CONFIGURATION,  // Link configuration and training
    RECOVERY,       // Recovery from idle or errors
    L0              // Normal operation (Active state)
  } ltssm_state_t;

  // PCIe Generation types
  typedef enum {
    GEN1 = 2,       // 2.5 GT/s
    GEN2 = 5,       // 5.0 GT/s
    GEN3 = 8        // 8.0 GT/s
  } pcie_gen_t;

  // Link speed in GT/s
  typedef enum {
    SPEED_2_5 = 25, // Gen1: 2.5 GT/s
    SPEED_5_0 = 50, // Gen2: 5.0 GT/s
    SPEED_8_0 = 80  // Gen3: 8.0 GT/s
  } ltssm_speed_t;

  // Link status indicators
  typedef struct {
    logic         link_up;           // Link training complete
    logic         electrical_idle;   // Link in electrical idle state
    logic         receiver_ready;    // Receiver ready for training
    logic         transmitter_ready; // Transmitter ready for training
    ltssm_speed_t negotiated_speed;  // Current negotiated speed
    pcie_gen_t    target_gen;        // Target generation for negotiation
  } ltssm_status_t;

  // Training parameters
  typedef struct {
    int unsigned  polling_timeout;        // Polling timeout in cycles
    int unsigned  config_timeout;         // Configuration timeout in cycles
    int unsigned  recovery_timeout;       // Recovery timeout in cycles
    int unsigned  detect_timeout;         // Detect timeout in cycles
    int unsigned  equ_preset;             // Equalization preset (Gen3 feature)
  } ltssm_params_t;

  // Training events
  typedef enum {
    TRAIN_START,           // Training started
    DETECT_ACK,            // Device detected
    ELECTRICAL_IDLE_DET,   // Electrical idle detected
    TS1_TS2_RCVD,          // Training sequences received
    EQ_COMPLETE,           // Equalization complete (Gen3)
    FRAMING_LOCK,          // Framing lock achieved
    LANE_REVERSAL_DET,     // Lane reversal detected
    ERROR_DETECTED,        // Error during training
    SPEED_CHANGE_REQ,      // Speed change requested
    LINK_UP                // Link reached L0
  } ltssm_event_t;

  // Base LTSSM state class for polymorphism
  virtual class ltssm_state;
    string name;
    function new(string n = ""); name = n; endfunction

    // Handle state entry/exit
    virtual function void on_entry(); endfunction
    virtual function void on_exit(); endfunction

    // Get next state based on conditions
    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt); 
      return DETECT;
    endfunction

    // Get state name for display
    virtual function string get_name(); 
      return name;
    endfunction
  endclass

  // Detect state - Device presence detection
  class ltssm_detect extends ltssm_state;
    function new(); super.new("DETECT"); endfunction
    
    virtual function void on_entry();
      $display("[LTSSM] Entering DETECT state - Looking for device presence on link");
    endfunction

    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt);
      // Device detected: move to Polling
      if (status.receiver_ready && status.transmitter_ready) begin
        $display("[LTSSM] DETECT -> POLLING (Device and receiver detected)");
        status.electrical_idle = 1'b0;
        return POLLING;
      end
      // Timeout: stay in Detect
      if (timeout_cnt > params.detect_timeout) begin
        $display("[LTSSM] DETECT: Timeout waiting for device presence");
        return DETECT;
      end
      return DETECT;
    endfunction
  endclass

  // Polling state - Speed capability negotiation and lane reversal detection
  class ltssm_polling extends ltssm_state;
    function new(); super.new("POLLING"); endfunction
    
    virtual function void on_entry();
      $display("[LTSSM] Entering POLLING state - Negotiating speed capability");
    endfunction

    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt);
      // Speed negotiated and TS1/TS2 sequences received
      if (status.transmitter_ready && status.receiver_ready && timeout_cnt > 5) begin
        // Negotiate speed: try Gen3, fallback to Gen2, then Gen1
        case (status.target_gen)
          GEN3: status.negotiated_speed = SPEED_8_0;
          GEN2: status.negotiated_speed = SPEED_5_0;
          GEN1: status.negotiated_speed = SPEED_2_5;
        endcase
        $display("[LTSSM] POLLING -> CONFIGURATION (Speed %0d GT/s negotiated)", status.negotiated_speed);
        return CONFIGURATION;
      end
      // Timeout: recovery needed
      if (timeout_cnt > params.polling_timeout) begin
        $display("[LTSSM] POLLING: Timeout, attempting recovery");
        return RECOVERY;
      end
      return POLLING;
    endfunction
  endclass

  // Configuration state - Link configuration and framing setup
  class ltssm_configuration extends ltssm_state;
    function new(); super.new("CONFIGURATION"); endfunction
    
    virtual function void on_entry();
      $display("[LTSSM] Entering CONFIGURATION state - Setting up link configuration");
    endfunction

    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt);
      // Configuration complete, framing locked
      if (timeout_cnt > 8) begin
        if (status.target_gen == GEN3) begin
          // Gen3 requires equalization
          if (timeout_cnt > 15) begin
            $display("[LTSSM] CONFIGURATION -> RECOVERY (Equalization needed for Gen3)");
            return RECOVERY;
          end
        end else begin
          // Gen1/Gen2 proceed directly to L0
          $display("[LTSSM] CONFIGURATION -> L0 (Link training complete)");
          status.link_up = 1'b1;
          return L0;
        end
      end
      // Timeout: return to polling
      if (timeout_cnt > params.config_timeout) begin
        $display("[LTSSM] CONFIGURATION: Timeout, returning to POLLING");
        return POLLING;
      end
      return CONFIGURATION;
    endfunction
  endclass

  // Recovery state - Equalization (Gen3) or error recovery
  class ltssm_recovery extends ltssm_state;
    function new(); super.new("RECOVERY"); endfunction
    
    virtual function void on_entry();
      $display("[LTSSM] Entering RECOVERY state - Equalizing link or recovering from errors");
    endfunction

    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt);
      // Equalization complete (Gen3) or error recovered
      if (timeout_cnt > 12) begin
        $display("[LTSSM] RECOVERY -> L0 (Link equalization/recovery complete)");
        status.link_up = 1'b1;
        status.electrical_idle = 1'b0;
        return L0;
      end
      // Timeout: attempt speed fallback
      if (timeout_cnt > params.recovery_timeout) begin
        $display("[LTSSM] RECOVERY: Timeout, attempting speed fallback");
        // Fallback logic: Gen3 -> Gen2 -> Gen1
        case (status.negotiated_speed)
          SPEED_8_0: begin
            status.negotiated_speed = SPEED_5_0;
            status.target_gen = GEN2;
            $display("[LTSSM] RECOVERY: Fallback to Gen2 (5.0 GT/s)");
          end
          SPEED_5_0: begin
            status.negotiated_speed = SPEED_2_5;
            status.target_gen = GEN1;
            $display("[LTSSM] RECOVERY: Fallback to Gen1 (2.5 GT/s)");
          end
          default: return DETECT; // Start over if all fallbacks exhausted
        endcase
        return POLLING; // Retry with reduced speed
      end
      return RECOVERY;
    endfunction
  endclass

  // L0 state - Normal operation (final state modeled)
  class ltssm_l0 extends ltssm_state;
    function new(); super.new("L0"); endfunction
    
    virtual function void on_entry();
      $display("[LTSSM] Entering L0 (Active) state - Link operational at %0d GT/s", $random);
      $display("[LTSSM] ========== LINK TRAINING COMPLETE ==========");
    endfunction

    virtual function ltssm_state_t get_next_state(ref ltssm_status_t status, ref ltssm_params_t params, int unsigned timeout_cnt);
      // L0 is the final modeled state - can remain or go to Recovery if error
      if (!status.link_up) begin
        $display("[LTSSM] L0 -> RECOVERY (Link error detected)");
        return RECOVERY;
      end
      return L0;
    endfunction
  endclass

  // LTSSM Context - manages state transitions for either RC or EP
  class ltssm_context;
    ltssm_state      current_state;
    ltssm_state_t    current_state_name;
    ltssm_status_t   link_status;
    ltssm_params_t   training_params;
    int unsigned     state_timeout_cnt;
    string           entity_type; // "RC" or "EP"

    function new(string type_str = "RC");
      ltssm_detect detect_state;
      
      entity_type = type_str;
      detect_state = new();
      current_state = detect_state;
      current_state_name = DETECT;
      state_timeout_cnt = 0;
      
      // Default status
      link_status.link_up = 1'b0;
      link_status.electrical_idle = 1'b1;
      link_status.receiver_ready = 1'b0;
      link_status.transmitter_ready = 1'b0;
      link_status.negotiated_speed = SPEED_2_5; // Start with Gen1
      link_status.target_gen = GEN3; // Try to negotiate Gen3
      
      // Default training parameters
      training_params.detect_timeout = 10;
      training_params.polling_timeout = 20;
      training_params.config_timeout = 25;
      training_params.recovery_timeout = 30;
      training_params.equ_preset = 0;
    endfunction

    // Process one cycle of LTSSM
    function void tick();
      ltssm_state_t next_state_name;
      ltssm_state new_state;

      state_timeout_cnt++;
      next_state_name = current_state.get_next_state(link_status, training_params, state_timeout_cnt);

      // State transition occurred
      if (next_state_name != current_state_name) begin
        current_state.on_exit();
        current_state_name = next_state_name;
        state_timeout_cnt = 0; // Reset timeout on state change

        // Instantiate new state object
        case (next_state_name)
          DETECT: begin
            ltssm_detect detect_state;
            detect_state = new();
            new_state = detect_state;
          end
          POLLING: begin
            ltssm_polling polling_state;
            polling_state = new();
            new_state = polling_state;
          end
          CONFIGURATION: begin
            ltssm_configuration config_state;
            config_state = new();
            new_state = config_state;
          end
          RECOVERY: begin
            ltssm_recovery recovery_state;
            recovery_state = new();
            new_state = recovery_state;
          end
          L0: begin
            ltssm_l0 l0_state;
            l0_state = new();
            new_state = l0_state;
          end
        endcase
        current_state = new_state;
        current_state.on_entry();
      end
    endfunction

    function ltssm_state_t get_current_state();
      return current_state_name;
    endfunction

    function string get_state_name();
      return current_state.get_name();
    endfunction

    function ltssm_status_t get_status();
      return link_status;
    endfunction
  endclass

endpackage : ltssm_pkg

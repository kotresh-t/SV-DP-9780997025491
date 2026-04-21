// State Design Pattern - Advanced Application
// ============================================
// Based on DVCON Paper Concepts: Adaptive Stimulus Generation Based on DUT State
// 
// Scenario: PCIe Link Training and Stimulus Generation
// The stimulus generator adapts its behavior based on the current state of the PCIe link
// monitored from the DUT. This follows the concept of "coverage-driven" and "state-aware"
// stimulus generation techniques presented in verification methodologies.
//
// Real-world Application:
// In high-speed serial protocols like PCIe, the link goes through various states
// (Detect, Polling, Configuration, L0 Active, etc.). The testbench stimulus generator
// must adapt its behavior based on these monitored states to generate valid transactions.

// ============================================================================
// Part 1: PCIe Link State Definitions
// ============================================================================
typedef class PCIeStimulus; 
typedef class PCIeLinkMonitor; 

class PCIeLinkState;
  virtual function string getStateName();
    return "UNKNOWN";
  endfunction
  
  virtual function void generateStimulus(PCIeStimulus stim_gen);
  endfunction
  
  virtual function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

class DetectState extends PCIeLinkState;
  function string getStateName();
    return "DETECT";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: DETECT] Generating EIDLE patterns for receiver detection...");
    $display("    -> Send 16 EIDLE symbols");
    $display("    -> Monitor for receiver presence (COM, SKP ordered sets)");
  endfunction
  
  function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

class PollingState extends PCIeLinkState;
  function string getStateName();
    return "POLLING";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: POLLING] Generating Polling.Active sequences...");
    $display("    -> Send TS1/TS2 training sequences");
    $display("    -> Monitor for receiver Lock (Bit Lock, Symbol Lock)");
    $display("    -> Verify lane number negotiation");
  endfunction
  
  function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

class ConfigurationState extends PCIeLinkState;
  function string getStateName();
    return "CONFIGURATION";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: CONFIGURATION] Generating speed/width negotiation...");
    $display("    -> Send TS1 sequences with target lane/speed info");
    $display("    -> Verify Link Width negotiation (x1, x4, x8, x16)");
    $display("    -> Verify Link Speed negotiation (Gen1/2/3/4/5)");
  endfunction
  
  function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

class L0ActiveState extends PCIeLinkState;
  function string getStateName();
    return "L0_ACTIVE";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: L0_ACTIVE] Link is fully trained! Generating TLP transactions...");
    $display("    -> Generate random TLP packets (Config, IO, Memory reads/writes)");
    $display("    -> Generate multiple concurrent transactions");
    $display("    -> Insert optional DLLP packets (Ack/Nak, Flow Control)");
    $display("    -> Apply protocol compliance checks");
  endfunction
  
  function bit isLinkReady();
    return 1'b1;
  endfunction
endclass

class L0sSubStateState extends PCIeLinkState;
  function string getStateName();
    return "L0s_SUBSTATE";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: L0s_SUBSTATE] Link in L0s (electrical idle substate)...");
    $display("    -> Stop sending TLP packets");
    $display("    -> Allow link to enter electrical idle for power savings");
    $display("    -> Wait for recovery to L0");
  endfunction
  
  function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

class ErrorState extends PCIeLinkState;
  function string getStateName();
    return "ERROR";
  endfunction
  
  function void generateStimulus(PCIeStimulus stim_gen);
    $display("  [PCIe State: ERROR] Link error detected!");
    $display("    -> STOP generating normal stimulus");
    $display("    -> Verify error handling and recovery");
    $display("    -> Log detailed error information");
    $display("    -> Optional: Trigger link retrain sequence");
  endfunction
  
  function bit isLinkReady();
    return 1'b0;
  endfunction
endclass

// ============================================================================
// Part 2: Monitored Link State Observer
// ============================================================================
// This class monitors the DUT and updates the current link state

class PCIeLinkMonitor;
  protected PCIeLinkState current_state;
  protected string last_event;
  protected int unsigned event_count;
  
  function new();
    DetectState detect_state;
    detect_state = new();
    current_state = detect_state;
    event_count = 0;
  endfunction
  
  function void updateState(PCIeLinkState new_state);
    current_state = new_state;
    event_count++;
  endfunction
  
  function PCIeLinkState getCurrentState();
    return current_state;
  endfunction
  
  function string getStateName();
    return current_state.getStateName();
  endfunction
  
  function int unsigned getEventCount();
    return event_count;
  endfunction
endclass

// ============================================================================
// Part 3: Adaptive Stimulus Generator (Context Class)
// ============================================================================
// Generates stimulus based on monitored link state
// This implements "coverage-driven stimulus generation" where test generation
// adapts to the current state of the DUT

class PCIeStimulus;
  protected PCIeLinkMonitor monitor;
  protected string test_name;
  protected int unsigned transaction_count;
  protected bit [15:0] generated_tlps;
  
  function new(string name, PCIeLinkMonitor mon);
    test_name = name;
    monitor = mon;
    transaction_count = 0;
    generated_tlps = 16'h0;
  endfunction
  
  // Core adaptive stimulus generation function
  // This is called periodically by the testbench
  function void generateAdaptiveStimulus();
    PCIeLinkState state;
    state = monitor.getCurrentState();
    
    $display("\n[STIMULUS GEN] Current Link State: %s", state.getStateName());
    
    // Call state-specific stimulus generation
    state.generateStimulus(this);
    
    // State-specific post-processing
    if (state.isLinkReady()) begin
      transaction_count++;
      $display("    -> Transaction #%0d generated", transaction_count);
    end
  endfunction
  
  // Transition functions - called when state changes occur in DUT
  function void onStateTransition(PCIeLinkState from_state, PCIeLinkState to_state);
    $display("\n[STATE TRANSITION] %s -> %s", from_state.getStateName(), to_state.getStateName());
    monitor.updateState(to_state);
  endfunction
  
  function int unsigned getTransactionCount();
    return transaction_count;
  endfunction
  
  function string getTestName();
    return test_name;
  endfunction
endclass

// ============================================================================
// Part 4: Advanced Example - Protocol State Machine with Metrics
// ============================================================================
// Real-world use case: Coverage tracking per state

class StateMetrics;
  string state_name;
  int unsigned visit_count;
  int unsigned stimulus_generated;
  int unsigned errors_detected;
  
  function new(string name);
    state_name = name;
    visit_count = 0;
    stimulus_generated = 0;
    errors_detected = 0;
  endfunction
  
  function void recordVisit();
    visit_count++;
  endfunction
  
  function void recordStimulus();
    stimulus_generated++;
  endfunction
  
  function void recordError();
    errors_detected++;
  endfunction
  
  function void printMetrics();
    $display("  [METRICS] %s:", state_name);
    $display("    Visits: %0d", visit_count);
    $display("    Stimulus Generated: %0d", stimulus_generated);
    $display("    Errors Detected: %0d", errors_detected);
  endfunction
endclass

// ============================================================================
// Part 5: Testbench Module - Simulating Real PCIe Link Training
// ============================================================================

module tb();

  class PCIeLinkTrainingTest;
    protected PCIeLinkMonitor link_monitor;
    protected PCIeStimulus stimulus_gen;
    protected StateMetrics detect_metrics;
    protected StateMetrics polling_metrics;
    protected StateMetrics config_metrics;
    protected StateMetrics l0_metrics;
    
    function new(string test_name);
      PCIeLinkMonitor monitor;
      PCIeStimulus stim_gen;
      
      monitor = new();
      link_monitor = monitor;
      stim_gen = new(test_name, monitor);
      stimulus_gen = stim_gen;
      
      detect_metrics = new("DETECT");
      polling_metrics = new("POLLING");
      config_metrics = new("CONFIGURATION");
      l0_metrics = new("L0_ACTIVE");
    endfunction
    
    task runTest();
      DetectState detect_state;
      PollingState polling_state;
      ConfigurationState config_state;
      L0ActiveState l0_state;
      ErrorState error_state;
      
      int cycle;
      
      $display("\n========================================");
      $display("PCIe LINK TRAINING - STATE DRIVEN TEST");
      $display("========================================\n");
      
      // Phase 1: Detect State (100 cycles)
      $display("[PHASE 1] DETECT STATE - Receiver Detection");
      $display("-------------------------------------------");
      detect_state = new();
      for (cycle = 0; cycle < 3; cycle++) begin
        detect_metrics.recordVisit();
        stimulus_gen.generateAdaptiveStimulus();
        detect_metrics.recordStimulus();
        #10;
      end
      
      // Transition to Polling
      polling_state = new();
      stimulus_gen.onStateTransition(detect_state, polling_state);
      #10;
      
      // Phase 2: Polling State (200 cycles)
      $display("\n[PHASE 2] POLLING STATE - Training Sequence Detection");
      $display("-------------------------------------------");
      for (cycle = 0; cycle < 3; cycle++) begin
        polling_metrics.recordVisit();
        stimulus_gen.generateAdaptiveStimulus();
        polling_metrics.recordStimulus();
        #10;
      end
      
      // Transition to Configuration
      config_state = new();
      stimulus_gen.onStateTransition(polling_state, config_state);
      #10;
      
      // Phase 3: Configuration State (300 cycles)
      $display("\n[PHASE 3] CONFIGURATION STATE - Speed/Width Negotiation");
      $display("-------------------------------------------");
      for (cycle = 0; cycle < 3; cycle++) begin
        config_metrics.recordVisit();
        stimulus_gen.generateAdaptiveStimulus();
        config_metrics.recordStimulus();
        #10;
      end
      
      // Transition to L0 Active
      l0_state = new();
      stimulus_gen.onStateTransition(config_state, l0_state);
      #10;
      
      // Phase 4: L0 Active - Full TLP Transaction Generation
      $display("\n[PHASE 4] L0 ACTIVE STATE - TLP Transaction Generation");
      $display("-------------------------------------------");
      for (cycle = 0; cycle < 5; cycle++) begin
        l0_metrics.recordVisit();
        stimulus_gen.generateAdaptiveStimulus();
        l0_metrics.recordStimulus();
        
        // Simulate error injection in cycle 3
        if (cycle == 3) begin
          $display("\n[ERROR INJECTION] Simulating link error...");
          error_state = new();
          stimulus_gen.onStateTransition(l0_state, error_state);
          error_state.generateStimulus(stimulus_gen);
          l0_metrics.recordError();
          #10;
          
          // Restart training
          $display("\n[RECOVERY] Link retraining initiated...");
          detect_state = new();
          stimulus_gen.onStateTransition(error_state, detect_state);
          #10;
          break;
        end
        #10;
      end
    endtask
    
    function void printTestSummary();
      $display("\n\n========================================");
      $display("TEST SUMMARY - STATE COVERAGE METRICS");
      $display("========================================\n");
      detect_metrics.printMetrics();
      $display("");
      polling_metrics.printMetrics();
      $display("");
      config_metrics.printMetrics();
      $display("");
      l0_metrics.printMetrics();
      $display("\nTotal Transactions Generated: %0d", stimulus_gen.getTransactionCount());
    endfunction
  endclass
  
  initial begin
    PCIeLinkTrainingTest test;
    test = new("PCIe_Link_Training_Test");
    test.runTest();
    test.printTestSummary();
    
    $display("\n========================================");
    $display("SIMULATION COMPLETE");
    $display("========================================\n");
    $finish;
  end

endmodule

/* 
# ========================================
# PCIe LINK TRAINING - STATE DRIVEN TEST
# ========================================
#
# [PHASE 1] DETECT STATE - Receiver Detection
# -------------------------------------------
#
# [STIMULUS GEN] Current Link State: DETECT
#   [PCIe State: DETECT] Generating EIDLE patterns for receiver detection...
#     -> Send 16 EIDLE symbols
#     -> Monitor for receiver presence (COM, SKP ordered sets)
#
# [STIMULUS GEN] Current Link State: DETECT
#   [PCIe State: DETECT] Generating EIDLE patterns for receiver detection...
#     -> Send 16 EIDLE symbols
#     -> Monitor for receiver presence (COM, SKP ordered sets)
#
# [STIMULUS GEN] Current Link State: DETECT
#   [PCIe State: DETECT] Generating EIDLE patterns for receiver detection...
#     -> Send 16 EIDLE symbols
#     -> Monitor for receiver presence (COM, SKP ordered sets)
#
# [STATE TRANSITION] DETECT -> POLLING
#
# [PHASE 2] POLLING STATE - Training Sequence Detection
# -------------------------------------------
#
# [STIMULUS GEN] Current Link State: POLLING
#   [PCIe State: POLLING] Generating Polling.Active sequences...
#     -> Send TS1/TS2 training sequences
#     -> Monitor for receiver Lock (Bit Lock, Symbol Lock)
#     -> Verify lane number negotiation
#
# [STIMULUS GEN] Current Link State: POLLING
#   [PCIe State: POLLING] Generating Polling.Active sequences...
#     -> Send TS1/TS2 training sequences
#     -> Monitor for receiver Lock (Bit Lock, Symbol Lock)
#     -> Verify lane number negotiation
#
# [STIMULUS GEN] Current Link State: POLLING
#   [PCIe State: POLLING] Generating Polling.Active sequences...
#     -> Send TS1/TS2 training sequences
#     -> Monitor for receiver Lock (Bit Lock, Symbol Lock)
#     -> Verify lane number negotiation
#
# [STATE TRANSITION] POLLING -> CONFIGURATION
#
# [PHASE 3] CONFIGURATION STATE - Speed/Width Negotiation
# -------------------------------------------
#
# [STIMULUS GEN] Current Link State: CONFIGURATION
#   [PCIe State: CONFIGURATION] Generating speed/width negotiation...
#     -> Send TS1 sequences with target lane/speed info
#     -> Verify Link Width negotiation (x1, x4, x8, x16)
#     -> Verify Link Speed negotiation (Gen1/2/3/4/5)
#
# [STIMULUS GEN] Current Link State: CONFIGURATION
#   [PCIe State: CONFIGURATION] Generating speed/width negotiation...
#     -> Send TS1 sequences with target lane/speed info
#     -> Verify Link Width negotiation (x1, x4, x8, x16)
#     -> Verify Link Speed negotiation (Gen1/2/3/4/5)
#
# [STIMULUS GEN] Current Link State: CONFIGURATION
#   [PCIe State: CONFIGURATION] Generating speed/width negotiation...
#     -> Send TS1 sequences with target lane/speed info
#     -> Verify Link Width negotiation (x1, x4, x8, x16)
#     -> Verify Link Speed negotiation (Gen1/2/3/4/5)
#
# [STATE TRANSITION] CONFIGURATION -> L0_ACTIVE
#
# [PHASE 4] L0 ACTIVE STATE - TLP Transaction Generation
# -------------------------------------------
#
# [STIMULUS GEN] Current Link State: L0_ACTIVE
#   [PCIe State: L0_ACTIVE] Link is fully trained! Generating TLP transactions...
#     -> Generate random TLP packets (Config, IO, Memory reads/writes)
#     -> Generate multiple concurrent transactions
#     -> Insert optional DLLP packets (Ack/Nak, Flow Control)
#     -> Apply protocol compliance checks
#     -> Transaction #1 generated
#
# [STIMULUS GEN] Current Link State: L0_ACTIVE
#   [PCIe State: L0_ACTIVE] Link is fully trained! Generating TLP transactions...
#     -> Generate random TLP packets (Config, IO, Memory reads/writes)
#     -> Generate multiple concurrent transactions
#     -> Insert optional DLLP packets (Ack/Nak, Flow Control)
#     -> Apply protocol compliance checks
#     -> Transaction #2 generated
#
# [STIMULUS GEN] Current Link State: L0_ACTIVE
#   [PCIe State: L0_ACTIVE] Link is fully trained! Generating TLP transactions...
#     -> Generate random TLP packets (Config, IO, Memory reads/writes)
#     -> Generate multiple concurrent transactions
#     -> Insert optional DLLP packets (Ack/Nak, Flow Control)
#     -> Apply protocol compliance checks
#     -> Transaction #3 generated
#
# [STIMULUS GEN] Current Link State: L0_ACTIVE
#   [PCIe State: L0_ACTIVE] Link is fully trained! Generating TLP transactions...
#     -> Generate random TLP packets (Config, IO, Memory reads/writes)
#     -> Generate multiple concurrent transactions
#     -> Insert optional DLLP packets (Ack/Nak, Flow Control)
#     -> Apply protocol compliance checks
#     -> Transaction #4 generated
#
# [ERROR INJECTION] Simulating link error...
#
# [STATE TRANSITION] L0_ACTIVE -> ERROR
#   [PCIe State: ERROR] Link error detected!
#     -> STOP generating normal stimulus
#     -> Verify error handling and recovery
#     -> Log detailed error information
#     -> Optional: Trigger link retrain sequence
#
# [RECOVERY] Link retraining initiated...
#
# [STATE TRANSITION] ERROR -> DETECT
#
#
# ========================================
# TEST SUMMARY - STATE COVERAGE METRICS
# ========================================
#
#   [METRICS] DETECT:
#     Visits: 3
#     Stimulus Generated: 3
#     Errors Detected: 0
#
#   [METRICS] POLLING:
#     Visits: 3
#     Stimulus Generated: 3
#     Errors Detected: 0
#
#   [METRICS] CONFIGURATION:
#     Visits: 3
#     Stimulus Generated: 3
#     Errors Detected: 0
#
#   [METRICS] L0_ACTIVE:
#     Visits: 4
#     Stimulus Generated: 4
#     Errors Detected: 1
#
# Total Transactions Generated: 4
#
# ========================================
# SIMULATION COMPLETE
# ========================================
*/
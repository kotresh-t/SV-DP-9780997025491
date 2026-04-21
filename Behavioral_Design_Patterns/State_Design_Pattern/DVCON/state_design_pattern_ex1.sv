// State Design Pattern in SystemVerilog
// ======================================
// Purpose: Define an object whose behavior changes based on its internal state.
// Each state is encapsulated in a separate class.
//
// Key Concepts:
// - Context: The object that has variable behavior (TrafficLight, MemoryController)
// - State: Abstract interface for different states
// - ConcreteState: Implements behavior for specific states
// - State transitions are managed by the Context or ConcreteStates

# ========================================
# STATE DESIGN PATTERN - SYSTEMVERILOG
# ========================================
#
# TEST 1: Traffic Light (Basic State Pattern)
# ---------------------------------------------
# Current Signal: RED
#   [Transition] RED -> GREEN
# Current Signal: GREEN
#   [Transition] GREEN -> YELLOW
# Current Signal: YELLOW
#   [Transition] YELLOW -> RED
# Current Signal: RED
#   [Transition] RED -> GREEN
# Current Signal: GREEN
#   [Transition] GREEN -> YELLOW
# Current Signal: YELLOW
#   [Transition] YELLOW -> RED
#
#
# TEST 2: USB Port (Hardware Verification Scenario)
# ---------------------------------------------
# Initial State: IDLE
#
#   [USB] Device connected. Moving to CONNECTED state.
# State: CONNECTED
#
#   [USB] Device configured. Moving to CONFIGURED state.
# State: CONFIGURED
#
#   [USB] Reset triggered. Returning to CONNECTED state.
# State: CONNECTED
#
#   [USB] Device disconnected. Returning to IDLE state.
# State: IDLE
#
#
#
# TEST 3: DRAM Controller (Hardware Verification Scenario)
# ---------------------------------------------
# Initial State: IDLE
#
#   [DRAM] Row activated. Moving to ACTIVE state.
# State: ACTIVE
#
#   [DRAM] Read command issued to active row. Moving to READ state.
# State: READ
#
#   [DRAM] Read completed. Back to ACTIVE state.
# State: ACTIVE
#
#   [DRAM] Row precharged. Moving to IDLE state.
# State: IDLE
#
#   [DRAM] Row activated. Moving to ACTIVE state.
#   [DRAM] Write command issued to active row. Moving to WRITE state.
# State: WRITE
#
#   [DRAM] Write completed. Back to ACTIVE state.
# State: ACTIVE
#
#   [DRAM] Row precharged. Moving to IDLE state.
# State: IDLE
#
module test_state_pattern();
// ============================================================================
// Example 1: Simple Traffic Light (Basic Fundamental Principles)
// ============================================================================
typedef class TrafficLight; 
typedef class USBPort; 
typedef class DRAMController; 

class TrafficLightState;
  virtual function string getColor();
    return "UNKNOWN";
  endfunction
  
  virtual function void transitionNext(TrafficLight traffic_context);
  endfunction
endclass
typedef class RedState; 
typedef class YellowState; 
typedef class GreenState; 
   
class YellowState extends TrafficLightState;
  function string getColor();
    return "YELLOW";
  endfunction
  
  function void transitionNext(TrafficLight traffic_context);
    RedState red_state;
    $display("  [Transition] YELLOW -> RED");
    red_state = new();
    traffic_context.setState(red_state);
  endfunction
endclass

class GreenState extends TrafficLightState;
  function string getColor();
    return "GREEN";
  endfunction
  
  function void transitionNext(TrafficLight traffic_context);
    YellowState yellow_state;
    $display("  [Transition] GREEN -> YELLOW");
    yellow_state = new();
    traffic_context.setState(yellow_state);
  endfunction
endclass

class RedState extends TrafficLightState;
  function string getColor();
    return "RED";
  endfunction
  
  function void transitionNext(TrafficLight traffic_context);
    GreenState green_state;
    $display("  [Transition] RED -> GREEN");
    green_state = new();
    traffic_context.setState(green_state);
  endfunction
endclass


class TrafficLight;
  protected TrafficLightState state;
  
  function new();
    RedState red_state;
    red_state = new();
    state = red_state;
  endfunction
  
  function void setState(TrafficLightState s);
    state = s;
  endfunction
  
  function string getCurrentColor();
    return state.getColor();
  endfunction
  
  function void changeSignal();
    state.transitionNext(this);
  endfunction
endclass

// ============================================================================
// Example 2: Hardware Verification Scenario - USB Port State Machine
// ============================================================================
// Simulates a USB port with different states: Idle, Connected, Configured, Error

class USBPortState;
  virtual function string getStateName();
    return "UNKNOWN";
  endfunction
  
  virtual function void connect(USBPort port);
  endfunction
  
  virtual function void disconnect(USBPort port);
  endfunction
  
  virtual function void configure(USBPort port);
  endfunction
  
  virtual function void reset(USBPort port);
  endfunction
endclass

typedef class IdleState; 
typedef class ConnectedState; 
typedef class ConfiguredState; 


class IdleState extends USBPortState;
  function string getStateName();
    return "IDLE";
  endfunction
  
  function void connect(USBPort port);
    ConnectedState connected_state;
    $display("  [USB] Device connected. Moving to CONNECTED state.");
    connected_state = new();
    port.setState(connected_state);
  endfunction
  
  function void disconnect(USBPort port);
    $display("  [USB] Already idle, nothing to disconnect.");
  endfunction
  
  function void configure(USBPort port);
    $display("  [USB ERROR] Cannot configure in IDLE state. Connect first.");
  endfunction
  
  function void reset(USBPort port);
    $display("  [USB] Reset in IDLE state (no-op).");
  endfunction
endclass

class ConnectedState extends USBPortState;
  function string getStateName();
    return "CONNECTED";
  endfunction
  
  function void connect(USBPort port);
    $display("  [USB ERROR] Already connected. Ignoring.");
  endfunction
  
  function void disconnect(USBPort port);
    IdleState idle_state;
    $display("  [USB] Device disconnected. Returning to IDLE state.");
    idle_state = new();
    port.setState(idle_state);
  endfunction
  
  function void configure(USBPort port);
    ConfiguredState configured_state;
    $display("  [USB] Device configured. Moving to CONFIGURED state.");
    configured_state = new();
    port.setState(configured_state);
  endfunction
  
  function void reset(USBPort port);
    IdleState idle_state;
    $display("  [USB] Reset triggered. Returning to IDLE state.");
    idle_state = new();
    port.setState(idle_state);
  endfunction
endclass

typedef class DRAMActiveState; 
typedef class DRAMReadState; 
typedef class DRAMWriteState; 

class ConfiguredState extends USBPortState;
  function string getStateName();
    return "CONFIGURED";
  endfunction
  
  function void connect(USBPort port);
    $display("  [USB ERROR] Already configured. Ignoring.");
  endfunction
  
  function void disconnect(USBPort port);
    IdleState idle_state;
    $display("  [USB] Device disconnected. Returning to IDLE state.");
    idle_state = new();
    port.setState(idle_state);
  endfunction
  
  function void configure(USBPort port);
    ConfiguredState configured_state;
    $display("  [USB] Already configured. Re-configuring...");
    configured_state = new();
    port.setState(configured_state);
  endfunction
  
  function void reset(USBPort port);
    ConnectedState connected_state;
    $display("  [USB] Reset triggered. Returning to CONNECTED state.");
    connected_state = new();
    port.setState(connected_state);
  endfunction
endclass

class USBPort;
  protected USBPortState state;
  protected string portName;
  
  function new(string name);
    IdleState idle_state;
    portName = name;
    idle_state = new();
    state = idle_state;
  endfunction
  
  function void setState(USBPortState s);
    state = s;
  endfunction
  
  function string getState();
    return state.getStateName();
  endfunction
  
  function void handleConnect();
    state.connect(this);
  endfunction
  
  function void handleDisconnect();
    state.disconnect(this);
  endfunction
  
  function void handleConfigure();
    state.configure(this);
  endfunction
  
  function void handleReset();
    state.reset(this);
  endfunction
endclass

// ============================================================================
// Example 3: Hardware Verification Scenario - DRAM Controller State Machine
// ============================================================================
// State transitions: Idle -> Activate -> Read -> Precharge -> Idle

class DRAMState;
  virtual function string getStateName();
    return "UNKNOWN";
  endfunction
  
  virtual function void activate(DRAMController ctrl);
  endfunction
  
  virtual function void read(DRAMController ctrl);
  endfunction
  
  virtual function void write(DRAMController ctrl);
  endfunction
  
  virtual function void precharge(DRAMController ctrl);
  endfunction
endclass

class DRAMIdleState extends DRAMState;
  function string getStateName();
    return "IDLE";
  endfunction
  
  function void activate(DRAMController ctrl);
    DRAMActiveState active_state;
    $display("  [DRAM] Row activated. Moving to ACTIVE state.");
    active_state = new();
    ctrl.setState(active_state);
  endfunction
  
  function void read(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot read in IDLE state.");
  endfunction
  
  function void write(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot write in IDLE state.");
  endfunction
  
  function void precharge(DRAMController ctrl);
    $display("  [DRAM] Already idle. Precharge not needed.");
  endfunction
endclass

class DRAMActiveState extends DRAMState;
  function string getStateName();
    return "ACTIVE";
  endfunction
  
  function void activate(DRAMController ctrl);
    $display("  [DRAM ERROR] Row already active.");
  endfunction
  
  function void read(DRAMController ctrl);
    DRAMReadState read_state;
    $display("  [DRAM] Read command issued to active row. Moving to READ state.");
    read_state = new();
    ctrl.setState(read_state);
  endfunction
  
  function void write(DRAMController ctrl);
    DRAMWriteState write_state;
    $display("  [DRAM] Write command issued to active row. Moving to WRITE state.");
    write_state = new();
    ctrl.setState(write_state);
  endfunction
  
  function void precharge(DRAMController ctrl);
    DRAMIdleState idle_state;
    $display("  [DRAM] Row precharged. Moving to IDLE state.");
    idle_state = new();
    ctrl.setState(idle_state);
  endfunction
endclass

class DRAMReadState extends DRAMState;
  function string getStateName();
    return "READ";
  endfunction
  
  function void activate(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot activate during read.");
  endfunction
  
  function void read(DRAMController ctrl);
    DRAMActiveState active_state;
    $display("  [DRAM] Read completed. Back to ACTIVE state.");
    active_state = new();
    ctrl.setState(active_state);
  endfunction
  
  function void write(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot write during read.");
  endfunction
  
  function void precharge(DRAMController ctrl);
    DRAMIdleState idle_state;
    $display("  [DRAM] Precharge issued. Moving to IDLE state.");
    idle_state = new();
    ctrl.setState(idle_state);
  endfunction
endclass

class DRAMWriteState extends DRAMState;
  function string getStateName();
    return "WRITE";
  endfunction
  
  function void activate(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot activate during write.");
  endfunction
  
  function void read(DRAMController ctrl);
    $display("  [DRAM ERROR] Cannot read during write.");
  endfunction
  
  function void write(DRAMController ctrl);
    DRAMActiveState active_state;
    $display("  [DRAM] Write completed. Back to ACTIVE state.");
    active_state = new();
    ctrl.setState(active_state);
  endfunction
  
  function void precharge(DRAMController ctrl);
    DRAMIdleState idle_state;
    $display("  [DRAM] Precharge issued. Moving to IDLE state.");
    idle_state = new();
    ctrl.setState(idle_state);
  endfunction
endclass

class DRAMController;
  protected DRAMState state;
  protected string name;
  
  function new(string n);
    DRAMIdleState idle_state;
    name = n;
    idle_state = new();
    state = idle_state;
  endfunction
  
  function void setState(DRAMState s);
    state = s;
  endfunction
  
  function string getState();
    return state.getStateName();
  endfunction
  
  function void issueActivate();
    state.activate(this);
  endfunction
  
  function void issueRead();
    state.read(this);
  endfunction
  
  function void issueWrite();
    state.write(this);
  endfunction
  
  function void issuePrecharge();
    state.precharge(this);
  endfunction
endclass

// ============================================================================
// Testbench - Demonstrate all three scenarios
// ============================================================================


  initial begin
    $display("\n========================================");
    $display("STATE DESIGN PATTERN - SYSTEMVERILOG");
    $display("========================================\n");
    
    // Test 1: Traffic Light
    $display("TEST 1: Traffic Light (Basic State Pattern)");
    $display("---------------------------------------------");
    begin
      TrafficLight tl;
      tl = new();
      repeat(6) begin
        $display("Current Signal: %s", tl.getCurrentColor());
        tl.changeSignal();
      end
    end
    
    $display("\n");
    
    // Test 2: USB Port State Machine
    $display("TEST 2: USB Port (Hardware Verification Scenario)");
    $display("---------------------------------------------");
    begin
      USBPort usb;
      usb = new("USB_Port_1");
      $display("Initial State: %s\n", usb.getState());
      
      usb.handleConnect();
      $display("State: %s\n", usb.getState());
      
      usb.handleConfigure();
      $display("State: %s\n", usb.getState());
      
      usb.handleReset();
      $display("State: %s\n", usb.getState());
      
      usb.handleDisconnect();
      $display("State: %s\n", usb.getState());
    end
    
    $display("\n");
    
    // Test 3: DRAM Controller State Machine
    $display("TEST 3: DRAM Controller (Hardware Verification Scenario)");
    $display("---------------------------------------------");
    begin
      DRAMController dram;
      dram = new("DRAM_1");
      $display("Initial State: %s\n", dram.getState());
      
      dram.issueActivate();
      $display("State: %s\n", dram.getState());
      
      dram.issueRead();
      $display("State: %s\n", dram.getState());
      
      dram.issueRead();
      $display("State: %s\n", dram.getState());
      
      dram.issuePrecharge();
      $display("State: %s\n", dram.getState());
      
      dram.issueActivate();
      dram.issueWrite();
      $display("State: %s\n", dram.getState());
      
      dram.issueWrite();
      $display("State: %s\n", dram.getState());
      
      dram.issuePrecharge();
      $display("State: %s\n", dram.getState());
    end
    
    $display("\n========================================");
    $display("SIMULATION COMPLETE");
    $display("========================================\n");
    $finish;
  end
endmodule
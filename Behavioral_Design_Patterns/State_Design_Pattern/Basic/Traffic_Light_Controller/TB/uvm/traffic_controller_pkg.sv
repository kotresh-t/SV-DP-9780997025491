`include "traffic_pkg.sv" 
`include "uvm_macros.svh"

package traffic_controller_pkg;

// Forward declarations for circular dependencies
typedef class tl_north_uvm;
typedef class tl_north_y_uvm;
typedef class tl_south_uvm;
typedef class tl_south_y_uvm;
typedef class tl_east_uvm;
typedef class tl_east_y_uvm;
typedef class tl_west_uvm;
typedef class tl_west_y_uvm;
typedef class tl_context_uvm;

import traffic_pkg::*;
import uvm_pkg::*;

`include "traffic_monitor.sv"
`include "traffic_scoreboard.sv"

`include "traffic_sequencer.sv"
`include "traffic_driver.sv"
`include "traffic_sequences.sv"
`include "traffic_state_design.sv"
`include "traffic_state_checker.sv"

`include "traffic_env.sv"

endpackage : traffic_controller_pkg

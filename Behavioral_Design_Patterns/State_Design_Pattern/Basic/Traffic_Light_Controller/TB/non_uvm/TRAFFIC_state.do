vlib work
vlog -sv ../RTL/traffic_light_controller.sv traffic_state_tb.sv
vsim -c work.traffic_state_tb -do "run -all; quit"
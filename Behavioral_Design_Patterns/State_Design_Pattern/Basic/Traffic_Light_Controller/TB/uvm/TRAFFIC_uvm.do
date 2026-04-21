vlib work
vlog -sv ../RTL/traffic_light_controller.sv traffic_if.sv traffic_pkg.sv traffic_state_design.sv traffic_state_checker.sv traffic_sequencer.sv traffic_driver.sv traffic_sequences.sv traffic_monitor.sv traffic_scoreboard.sv traffic_env.sv traffic_test.sv traffic_tb_uvm.sv
vsim -novopt work.traffic_tb_uvm -do "run -all; quit" -uvm
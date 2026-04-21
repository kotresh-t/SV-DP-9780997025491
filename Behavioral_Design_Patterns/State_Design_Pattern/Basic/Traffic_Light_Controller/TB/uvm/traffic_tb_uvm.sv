`timescale 1ns/1ps

`include "traffic_light_controller.sv"
`include "traffic_if.sv"
`include "traffic_pkg.sv"
`include "traffic_controller_pkg.sv" 
module traffic_tb_uvm();


import uvm_pkg::*;
import traffic_pkg::*;
import traffic_controller_pkg::*;
`include "traffic_test.sv"



  // DUT signals
  wire [2:0] n_lights, s_lights, e_lights, w_lights;
  reg clk;
  reg rst_a;

  // virtual interface instance
  traffic_if vif();

  // instantiate DUT and connect to interface
  traffic_control dut(
    .n_lights(vif.n_lights),
    .s_lights(vif.s_lights),
    .e_lights(vif.e_lights),
    .w_lights(vif.w_lights),
    .clk(vif.clk),
    .rst_a(vif.rst_a)
  );

  // clock generator
  initial begin
    vif.clk = 0;
    forever #5 vif.clk = ~vif.clk;
  end

  // publish virtual interface and start UVM at time 0 (no time must elapse before run_test)
  initial begin
    uvm_config_db#(virtual traffic_if)::set(null, "*", "vif", vif);
    run_test("traffic_test");
  end

  // reset sequence runs concurrently with UVM (allowed)
  initial begin
    vif.rst_a = 1'b1;
    repeat(3) @(posedge vif.clk);
    vif.rst_a = 1'b0;
  end

endmodule
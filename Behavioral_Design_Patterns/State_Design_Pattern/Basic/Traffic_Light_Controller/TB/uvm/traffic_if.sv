interface traffic_if();
  logic clk;
  logic rst_a;
  logic [2:0] n_lights, s_lights, e_lights, w_lights;

  // clocking block to synchronize monitor/driver access
  clocking cb @(posedge clk);
    input n_lights;
    input s_lights;
    input e_lights;
    input w_lights;
    input rst_a;
  endclocking

endinterface
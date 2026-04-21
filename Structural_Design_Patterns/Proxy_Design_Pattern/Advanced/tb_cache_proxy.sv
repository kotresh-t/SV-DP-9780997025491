/*
  Top for Proxy Design Pattern (Cache as Proxy) - UVM + RTL
*/
module tb_cache_proxy;
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import cache_proxy_pkg::*;

  logic clk;
  always #5 clk = ~clk;

  cache_if cache_vif(clk);

  cache_proxy_dut #(
    .LINES(8),
    .WORDS_PER_LINE(4),
    .MEM_WORDS(1024)
  ) dut (
    .clk       (clk),
    .rst_n     (cache_vif.rst_n),
    .req_valid (cache_vif.req_valid),
    .req_write (cache_vif.req_write),
    .req_addr  (cache_vif.req_addr),
    .req_wdata (cache_vif.req_wdata),
    .req_ready (cache_vif.req_ready),
    .rsp_valid (cache_vif.rsp_valid),
    .rsp_rdata (cache_vif.rsp_rdata)
  );

  initial begin
    clk = 1'b0;
    cache_vif.rst_n = 1'b0;
    cache_vif.req_valid = 1'b0;
    cache_vif.req_write = 1'b0;
    cache_vif.req_addr  = '0;
    cache_vif.req_wdata = '0;

    uvm_config_db#(virtual cache_if.tb)::set(null, "uvm_test_top.env.agent.driver", "vif", cache_vif);

    run_test("cache_proxy_test");
    $finish;
  end
endmodule

/*
  Cache interface between UVM TB and DUT
*/
interface cache_if(input bit clk);
  logic        rst_n;
  logic        req_valid;
  logic        req_write;
  logic [31:0] req_addr;
  logic [31:0] req_wdata;
  logic        req_ready;
  logic        rsp_valid;
  logic [31:0] rsp_rdata;

  modport dut (
    input  clk, rst_n, req_valid, req_write, req_addr, req_wdata,
    output req_ready, rsp_valid, rsp_rdata
  );

  modport tb (
    input  clk, req_ready, rsp_valid, rsp_rdata,
    output rst_n, req_valid, req_write, req_addr, req_wdata
  );
endinterface

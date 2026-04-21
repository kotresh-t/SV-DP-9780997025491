`timescale 1ns/1ps

`ifndef AXI_IF_SV
`define AXI_IF_SV
interface axi_if (input logic clk, rstn);
  logic [31:0] awaddr;
  logic        awvalid;
  logic        awready;
  logic [2:0]  awsize;
  logic [7:0]  awlen;
  logic [3:0]  awid;

  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wvalid;
  logic        wready;
  logic        wlast;

  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;

  logic [31:0] araddr;
  logic        arvalid;
  logic        arready;
  logic [2:0]  arsize;
  logic [7:0]  arlen;
  logic [3:0]  arid;

  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;
  logic        rlast;

  modport dut (
    input  clk, rstn, awaddr, awvalid, awsize, awlen, awid, wdata, wstrb, wvalid, wlast, bready,
           araddr, arvalid, arsize, arlen, arid, rready,
    output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid, rlast
  );

  modport driver (
    output awaddr, awvalid, awsize, awlen, awid, wdata, wstrb, wvalid, wlast, bready,
           araddr, arvalid, arsize, arlen, arid, rready,
    input  awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid, rlast
  );

  modport monitor (
    input awaddr, awvalid, awsize, awlen, awid, wdata, wstrb, wvalid, wlast, bresp, bvalid,
          araddr, arvalid, arsize, arlen, arid, rdata, rresp, rvalid, rlast,
          awready, wready, bready, arready, rready
  );
endinterface
`endif

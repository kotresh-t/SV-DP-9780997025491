interface axi_if(input bit clk);
  logic [31:0] awaddr;
  logic [31:0] wdata;
  logic        awvalid, awready;
endinterface
`ifndef AXI_TRANS_SV
`define AXI_TRANS_SV

// For convenience lets take on AXI Address Channel. 
// We will ignore protocol nuances as it will become more complicated with additional logic. 

class axi_transaction;

  rand logic [31:0] awaddr, wdata;
  rand logic [7:0] awlen;
  rand logic [2:0] awsize;
  rand logic awvalid, wvalid, wlast;

  // Constructor
  function new();
    awvalid = 0;
    wvalid = 0;
    wlast = 0;
  endfunction

  // Pack data into a bit stream
  function bit [147:0] pack();
    return {awaddr, wdata, awlen, awsize, awvalid, wvalid, wlast};
  endfunction

  // Unpack data from a bit stream
  task unpack(bit [147:0] packed_data);
    {awaddr, wdata, awlen, awsize, awvalid, wvalid, wlast} = packed_data;
  endtask

endclass

`endif // AXI_TRANS_SV


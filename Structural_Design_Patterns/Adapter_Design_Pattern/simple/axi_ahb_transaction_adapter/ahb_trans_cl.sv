`ifndef AHB_TRANS_SV
`define AHB_TRANS_SV

class ahb_transaction;
  rand logic [31:0] haddr, hwdata;
  rand logic [2:0] hsize;
  rand logic hwrite, hready;

  // Constructor
  function new();
    hwrite = 0;
    hready = 0;
  endfunction

  // Pack data into a bit stream
  function bit [71:0] pack();
    return {haddr, hwdata, hsize, hwrite, hready};
  endfunction

  // Unpack data from a bit stream
  task unpack(bit [71:0] packed_data);
    {haddr, hwdata, hsize, hwrite, hready} = packed_data;
  endtask
endclass

`endif AHB_TRANS_SV

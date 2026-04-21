// pcie_dllp_trx_if.sv
interface pcie_dllp_trx_if;
logic        valid;
pcie_dllp_item trx;
event        put_event;

// Task to send a transaction
task put(input pcie_dllp_item t);
  trx = t;
  valid = 1;
  -> put_event;
  #1; // optional small delay
  valid = 0;
endtask

// Function to get (non-blocking)
function automatic pcie_dllp_item get();
  if (valid) return trx;
  else return null;
endfunction

endinterface
module pcie_builder_tb(); 

`include "uvm_macros.svh" 
import uvm_pkg::*; 

`include "pcie_tlp_env.sv" 
`include "pcie_link_env.sv"
`include "pcie_phy_env.sv"
`include "pcie_virtual_sequencer.sv"
`include "pcie_env_builder.sv"
`include "pcie_env.sv"

pcie_env env;

initial begin 
    env = pcie_env::type_id::create("env", null);
end

endmodule 
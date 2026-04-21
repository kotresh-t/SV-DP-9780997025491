`ifndef SINGLETON_CONFIG_PKG
`define SINGLETON_CONFIG_PKG

package singleton_config_pkg;
    `include "simulation_parameters_singleton.sv"
    `include "feature_toggles_singleton.sv"
    `include "debug_settings_singleton.sv"
endpackage

`endif // SINGLETON_CONFIG_PKG


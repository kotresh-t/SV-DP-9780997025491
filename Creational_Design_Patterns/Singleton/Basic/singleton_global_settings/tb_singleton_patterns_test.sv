// Package can be created in seperate file. 
package single_ton_config_pkg; 

`include "simulation_param_cl.sv"
`include "debug_settings_cl.sv"
`include "feature_toggles_cl.sv"

endpackage // single_ton_config_pkg

module tb_singleton_patterns_test(); 

    import single_ton_config_pkg::*; 

    // Instantiate Singleton classes
    SimulationParametersSingleton sim_params;
    FeatureTogglesSingleton 	  feature_toggles;
    DebugSettingsSingleton 	  debug_settings;

    initial begin

        // Retrieve Singleton instances
        feature_toggles = FeatureTogglesSingleton::getInstance();
        debug_settings = DebugSettingsSingleton::getInstance();

        // Example: Use of Singleton settings in the testbench
	// Logger Settings
        if (debug_settings.verbose_logging) begin
            $display("Verbose logging enabled.");
        end

	// Feature Settings
        if (feature_toggles.enable_feature_a) begin
            $display("Feature A is enabled.");
        end
   
   end 

   initial begin 

        // Singleton for simulation parameters. 
	sim_params = SimulationParametersSingleton::getInstance();

        // Set simulation time based on Singleton
        #sim_params.simulation_time;
        $display("Simulation time completed.");

        $finish;

    end	

endmodule // tb_singleton_patterns_test

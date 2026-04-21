`ifndef CONFIG_REGR_SV
`define CONFIG_REGR_SV

class config_regr extends register; 

	virtual function void perform_specific_verification(); 
		// Specific Verification for config registers. 
	endfunction // perform_specific_verification

endclass // config_regr

`endif // CONFIG_REGR_SV

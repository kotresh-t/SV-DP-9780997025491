`ifndef regr_template_sv
`define regr_template_sv

virtual class Register_Verification; 

	// Common Verification Steps. 
	virtual function void perform_common_verification(); 
	endfunction // perform_common_verification

	//Specific Verification Steps. 
	virtual function void perform_specific_verification();
	endfunction // perform_specific_verification

	//Template Method.
	function void verify_register(); 
		perform_common_verification(); 
		perform_specific_verification(); 
	endfunction // verify_register. 

endclass // Register_Verification


`endif // regr_template_sv

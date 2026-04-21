`ifndef UvmReportDecorator_SV
`define UvmReportDecorator_SV

class UvmReportDecorator extends uvm_report_catcher;
    `uvm_object_utils(UvmReportDecorator)

    function new(string name="UvmReportDecorator");
        super.new(name);
    endfunction

    protected function bit is_driver_message();
        string id;

        id = get_id();
        return (id.len() >= 4) && (id.substr(id.len()-4, id.len()-1) == ".drv");
    endfunction

    virtual function action_e catch();
        string modified_message;

        modified_message = get_message();

        if (get_severity() == UVM_ERROR) begin
            modified_message = {modified_message, "\n[ERROR DIAGNOSTICS] Detailed diagnostics here."};
            set_message(modified_message);
        end

        if (get_severity() == UVM_INFO && is_driver_message()) begin
            modified_message = {"[Decorated] ", modified_message, " [PerfMetrics enabled]"};
            set_message(modified_message);
        end

        return THROW;
    endfunction
endclass

`endif // UvmReportDecorator_SV 

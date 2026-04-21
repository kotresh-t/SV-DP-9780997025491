`ifndef my_test_sv
`define my_test_sv

// A simple UVM test
class my_test extends uvm_test;
    `uvm_component_utils(my_test)
    my_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        UvmReportDecorator rpt_dec;
        super.build_phase(phase);
        env = my_env::type_id::create("env", this);
        rpt_dec = new();
        uvm_report_cb::add(null, rpt_dec);
    endfunction

    virtual task run_phase(uvm_phase phase);
        my_sequence seq;

        phase.raise_objection(this);
        seq = my_sequence::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass


`endif // my_test_sv

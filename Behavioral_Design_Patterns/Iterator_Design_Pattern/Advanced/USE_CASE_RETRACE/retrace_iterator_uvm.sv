`include "../iterator_uvm_common_pkg.sv"

import uvm_pkg::*;
import iterator_uvm_common_pkg::*;
`include "uvm_macros.svh"

class retrace_iterator_analyzer extends uvm_subscriber #(iterator_txn);
  `uvm_component_utils(retrace_iterator_analyzer)

  iterator_transaction_collection failure_history;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    failure_history = new("failure_history");
  endfunction

  function void write(iterator_txn t);
    failure_history.add(t);
  endfunction

  function void report_phase(uvm_phase phase);
    reverse_iterator #(iterator_txn) iter;
    iterator_txn txn;
    int step;

    super.report_phase(phase);

    iter = failure_history.create_reverse_iterator();
    step = 0;

    `uvm_info(get_type_name(), "===== Failure Retrace =====", UVM_LOW)
    while (iter.has_next()) begin
      txn = iter.get_next();
      `uvm_info(
        get_type_name(),
        $sformatf("Retrace step %0d -> %s", step, txn.convert2string()),
        UVM_LOW
      )
      step++;
    end
  endfunction
endclass

class retrace_iterator_env extends uvm_env;
  `uvm_component_utils(retrace_iterator_env)

  iterator_source            src;
  retrace_iterator_analyzer  analyzer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    src = iterator_source::type_id::create("src", this);
    analyzer = retrace_iterator_analyzer::type_id::create("analyzer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    src.ap.connect(analyzer.analysis_export);
  endfunction
endclass

class retrace_iterator_test extends uvm_test;
  `uvm_component_utils(retrace_iterator_test)

  retrace_iterator_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = retrace_iterator_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    iterator_txn txn;

    super.end_of_elaboration_phase(phase);

    txn = iterator_txn::type_id::create("txn_0");
    txn.seq_id = 0;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_1000;
    txn.data = 32'h1111_AAAA;
    txn.phase_name = "SETUP";
    txn.status = ITER_STATUS_OK;
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_1");
    txn.seq_id = 1;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_1004;
    txn.data = 32'h2222_BBBB;
    txn.phase_name = "CONFIG";
    txn.status = ITER_STATUS_OK;
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_2");
    txn.seq_id = 2;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_1008;
    txn.data = 32'h3333_CCCC;
    txn.phase_name = "ACCESS";
    txn.status = ITER_STATUS_RETRY;
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_3");
    txn.seq_id = 3;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_100C;
    txn.data = 32'h4444_DDDD;
    txn.phase_name = "CHECK";
    txn.status = ITER_STATUS_FAIL;
    txn.violation_detected = 1;
    txn.violation_reason = "Readback mismatch";
    env.src.add_txn(txn);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #10ns;
    phase.drop_objection(this);
  endtask
endclass

module retrace_iterator_uvm_top;
  initial begin
    run_test("retrace_iterator_test");
  end
endmodule

/* 
 UVM_INFO @ 0: reporter [RNTST] Running test retrace_iterator_test...
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 0: uvm_test_top.env.src [iterator_source] Publishing id=0 cmd=WRITE phase=SETUP status=OK addr=0x00001000 data=0x1111aaaa violation=0 reason=
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 1: uvm_test_top.env.src [iterator_source] Publishing id=1 cmd=WRITE phase=CONFIG status=OK addr=0x00001004 data=0x2222bbbb violation=0 reason=
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 2: uvm_test_top.env.src [iterator_source] Publishing id=2 cmd=READ phase=ACCESS status=RETRY addr=0x00001008 data=0x3333cccc violation=0 reason=
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 3: uvm_test_top.env.src [iterator_source] Publishing id=3 cmd=READ phase=CHECK status=FAIL addr=0x0000100c data=0x4444dddd violation=1 reason=Readback mismatch
# UVM_INFO verilog_src/uvm-1.2/src/base/uvm_objection.svh(1271) @ 10: reporter [TEST_DONE] 'run' phase is ready to proceed to the 'extract' phase
# UVM_INFO .\retrace_iterator_uvm.sv(31) @ 10: uvm_test_top.env.analyzer [retrace_iterator_analyzer] ===== Failure Retrace =====
# UVM_INFO .\retrace_iterator_uvm.sv(38) @ 10: uvm_test_top.env.analyzer [retrace_iterator_analyzer] Retrace step 0 -> id=3 cmd=READ phase=CHECK status=FAIL addr=0x0000100c data=0x4444dddd violation=1 reason=Readback mismatch
# UVM_INFO .\retrace_iterator_uvm.sv(38) @ 10: uvm_test_top.env.analyzer [retrace_iterator_analyzer] Retrace step 1 -> id=2 cmd=READ phase=ACCESS status=RETRY addr=0x00001008 data=0x3333cccc violation=0 reason=
# UVM_INFO .\retrace_iterator_uvm.sv(38) @ 10: uvm_test_top.env.analyzer [retrace_iterator_analyzer] Retrace step 2 -> id=1 cmd=WRITE phase=CONFIG status=OK addr=0x00001004 data=0x2222bbbb violation=0 reason=
# UVM_INFO .\retrace_iterator_uvm.sv(38) @ 10: uvm_test_top.env.analyzer [retrace_iterator_analyzer] Retrace step 3 -> id=0 cmd=WRITE phase=SETUP status=OK addr=0x00001000 data=0x1111aaaa violation=0 reason=
# UVM_INFO verilog_src/uvm-1.2/src/base/uvm_report_server.svh(847) @ 10: reporter [UVM/REPORT/SERVER] 
*/ 

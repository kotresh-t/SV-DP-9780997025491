`include "../iterator_uvm_common_pkg.sv"

import uvm_pkg::*;
import iterator_uvm_common_pkg::*;
`include "uvm_macros.svh"

class iterator_violation_predicate extends filter_predicate #(iterator_txn);
  `uvm_object_utils(iterator_violation_predicate)

  function new(string name = "iterator_violation_predicate");
    super.new(name);
  endfunction

  virtual function bit match(iterator_txn item);
    return (item != null) && item.violation_detected;
  endfunction
endclass

class constraint_violation_analyzer extends uvm_subscriber #(iterator_txn);
  `uvm_component_utils(constraint_violation_analyzer)

  iterator_transaction_collection history;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    history = new("history");
  endfunction

  function void write(iterator_txn t);
    history.add(t);
  endfunction

  function void report_phase(uvm_phase phase);
    filtered_iterator #(iterator_txn) iter;
    iterator_violation_predicate pred;
    iterator_txn txn;
    int violation_count;
    int alignment_count;
    int protection_count;
    int protocol_count;

    super.report_phase(phase);

    pred = iterator_violation_predicate::type_id::create("pred");
    iter = history.create_filtered_iterator(pred);
    violation_count = 0;
    alignment_count = 0;
    protection_count = 0;
    protocol_count = 0;

    `uvm_info(get_type_name(), "===== Constraint Violation Report =====", UVM_LOW)
    while (iter.has_next()) begin
      txn = iter.get_next();
      violation_count++;

      if (txn.violation_reason == "Alignment") begin
        alignment_count++;
      end
      else if (txn.violation_reason == "Protection") begin
        protection_count++;
      end
      else begin
        protocol_count++;
      end

      `uvm_info(
        get_type_name(),
        $sformatf("Violation #%0d -> %s", violation_count, txn.convert2string()),
        UVM_LOW
      )
    end

    `uvm_info(
      get_type_name(),
      $sformatf(
        "Total violations=%0d alignment=%0d protection=%0d protocol=%0d",
        violation_count, alignment_count, protection_count, protocol_count
      ),
      UVM_LOW
    )
  endfunction
endclass

class constraint_violation_env extends uvm_env;
  `uvm_component_utils(constraint_violation_env)

  iterator_source                src;
  constraint_violation_analyzer  analyzer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    src = iterator_source::type_id::create("src", this);
    analyzer = constraint_violation_analyzer::type_id::create("analyzer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    src.ap.connect(analyzer.analysis_export);
  endfunction
endclass

class constraint_violation_test extends uvm_test;
  `uvm_component_utils(constraint_violation_test)

  constraint_violation_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = constraint_violation_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    iterator_txn txn;

    super.end_of_elaboration_phase(phase);

    txn = iterator_txn::type_id::create("txn_0");
    txn.seq_id = 0;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_4000;
    txn.data = 32'h0101_0101;
    txn.phase_name = "GEN";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_1");
    txn.seq_id = 1;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_4002;
    txn.data = 32'h0202_0202;
    txn.phase_name = "CHECK";
    txn.violation_detected = 1;
    txn.violation_reason = "Alignment";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_2");
    txn.seq_id = 2;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'hFFFF_0000;
    txn.data = 32'h0303_0303;
    txn.phase_name = "ACCESS";
    txn.violation_detected = 1;
    txn.violation_reason = "Protection";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_3");
    txn.seq_id = 3;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_4010;
    txn.data = 32'h0404_0404;
    txn.phase_name = "CHECK";
    txn.violation_detected = 1;
    txn.violation_reason = "Protocol";
    env.src.add_txn(txn);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #10ns;
    phase.drop_objection(this);
  endtask
endclass

module constraint_violation_iterator_uvm_top;
  initial begin
    run_test("constraint_violation_test");
  end
endmodule

/* 
# UVM_INFO @ 0: reporter [RNTST] Running test constraint_violation_test...
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 0: uvm_test_top.env.src [iterator_source] Publishing id=0 cmd=WRITE phase=GEN status=OK addr=0x00004000 data=0x01010101 violation=0 reason=
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 1: uvm_test_top.env.src [iterator_source] Publishing id=1 cmd=READ phase=CHECK status=OK addr=0x00004002 data=0x02020202 violation=1 reason=Alignment
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 2: uvm_test_top.env.src [iterator_source] Publishing id=2 cmd=WRITE phase=ACCESS status=OK addr=0xffff0000 data=0x03030303 violation=1 reason=Protection
# UVM_INFO ../iterator_uvm_common_pkg.sv(302) @ 3: uvm_test_top.env.src [iterator_source] Publishing id=3 cmd=READ phase=CHECK status=OK addr=0x00004010 data=0x04040404 violation=1 reason=Protocol
# UVM_INFO verilog_src/uvm-1.2/src/base/uvm_objection.svh(1271) @ 10: reporter [TEST_DONE] 'run' phase is ready to proceed to the 'extract' phase
# UVM_INFO .\constraint_violation_iterator_uvm.sv(51) @ 10: uvm_test_top.env.analyzer [constraint_violation_analyzer] ===== Constraint Violation Report =====
# UVM_INFO .\constraint_violation_iterator_uvm.sv(70) @ 10: uvm_test_top.env.analyzer [constraint_violation_analyzer] Violation #1 -> id=1 cmd=READ phase=CHECK status=OK addr=0x00004002 data=0x02020202 violation=1 reason=Alignment
# UVM_INFO .\constraint_violation_iterator_uvm.sv(70) @ 10: uvm_test_top.env.analyzer [constraint_violation_analyzer] Violation #2 -> id=2 cmd=WRITE phase=ACCESS status=OK addr=0xffff0000 data=0x03030303 violation=1 reason=Protection
# UVM_INFO .\constraint_violation_iterator_uvm.sv(70) @ 10: uvm_test_top.env.analyzer [constraint_violation_analyzer] Violation #3 -> id=3 cmd=READ phase=CHECK status=OK addr=0x00004010 data=0x04040404 violation=1 reason=Protocol
# UVM_INFO .\constraint_violation_iterator_uvm.sv(80) @ 10: uvm_test_top.env.analyzer [constraint_violation_analyzer] Total violations=3 alignment=1 protection=1 protocol=1
# UVM_INFO verilog_src/uvm-1.2/src/base/uvm_report_server.svh(847) @ 10: reporter [UVM/REPORT/SERVER] 
# --- UVM Report Summary ---
*/ 

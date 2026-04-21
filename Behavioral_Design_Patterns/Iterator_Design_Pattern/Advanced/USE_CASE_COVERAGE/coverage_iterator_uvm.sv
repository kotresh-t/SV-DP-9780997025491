`include "../iterator_uvm_common_pkg.sv"

import uvm_pkg::*;
import iterator_uvm_common_pkg::*;
`include "uvm_macros.svh"

class coverage_iterator_analyzer extends uvm_subscriber #(iterator_txn);
  `uvm_component_utils(coverage_iterator_analyzer)

  iterator_transaction_collection history;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    history = new("history");
  endfunction

  function void write(iterator_txn t);
    history.add(t);
  endfunction

  function void report_phase(uvm_phase phase);
    queue_iterator #(iterator_txn) iter;
    iterator_txn txn;
    iterator_txn prev_txn;
    int read_count;
    int write_count;
    int low_region_count;
    int mid_region_count;
    int high_region_count;
    int sequential_burst_count;

    super.report_phase(phase);

    iter = history.create_forward_iterator();
    read_count = 0;
    write_count = 0;
    low_region_count = 0;
    mid_region_count = 0;
    high_region_count = 0;
    sequential_burst_count = 0;
    prev_txn = null;

    `uvm_info(get_type_name(), "===== Coverage Summary =====", UVM_LOW)
    while (iter.has_next()) begin
      txn = iter.get_next();

      if (txn.cmd == ITER_READ) begin
        read_count++;
      end
      else begin
        write_count++;
      end

      if (txn.addr < 32'h0000_2008) begin
        low_region_count++;
      end
      else if (txn.addr < 32'h0000_3000) begin
        mid_region_count++;
      end
      else begin
        high_region_count++;
      end

      if ((prev_txn != null) && (txn.addr == (prev_txn.addr + 32'd4))) begin
        sequential_burst_count++;
      end

      prev_txn = txn;
    end

    `uvm_info(
      get_type_name(),
      $sformatf(
        "Transactions=%0d Reads=%0d Writes=%0d",
        history.get_size(), read_count, write_count
      ),
      UVM_LOW
    )
    `uvm_info(
      get_type_name(),
      $sformatf(
        "Address regions: low=%0d mid=%0d high=%0d sequential_steps=%0d",
        low_region_count, mid_region_count, high_region_count, sequential_burst_count
      ),
      UVM_LOW
    )
  endfunction
endclass

class coverage_iterator_env extends uvm_env;
  `uvm_component_utils(coverage_iterator_env)

  iterator_source            src;
  coverage_iterator_analyzer analyzer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    src = iterator_source::type_id::create("src", this);
    analyzer = coverage_iterator_analyzer::type_id::create("analyzer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    src.ap.connect(analyzer.analysis_export);
  endfunction
endclass

class coverage_iterator_test extends uvm_test;
  `uvm_component_utils(coverage_iterator_test)

  coverage_iterator_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = coverage_iterator_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    iterator_txn txn;

    super.end_of_elaboration_phase(phase);

    txn = iterator_txn::type_id::create("txn_0");
    txn.seq_id = 0;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_2000;
    txn.data = 32'hAAAA_0001;
    txn.phase_name = "SAMPLE";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_1");
    txn.seq_id = 1;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_2004;
    txn.data = 32'hBBBB_0002;
    txn.phase_name = "SAMPLE";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_2");
    txn.seq_id = 2;
    txn.cmd = ITER_READ;
    txn.addr = 32'h0000_2008;
    txn.data = 32'hCCCC_0003;
    txn.phase_name = "SAMPLE";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_3");
    txn.seq_id = 3;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_200C;
    txn.data = 32'hDDDD_0004;
    txn.phase_name = "SAMPLE";
    env.src.add_txn(txn);

    txn = iterator_txn::type_id::create("txn_4");
    txn.seq_id = 4;
    txn.cmd = ITER_WRITE;
    txn.addr = 32'h0000_3100;
    txn.data = 32'hEEEE_0005;
    txn.phase_name = "SAMPLE";
    env.src.add_txn(txn);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #10ns;
    phase.drop_objection(this);
  endtask
endclass

module coverage_iterator_uvm_top;
  initial begin
    run_test("coverage_iterator_test");
  end
endmodule


// Coverage-driven extension for the Strategy pattern example.
// This stays compatible with the address-centric API used in Book_Example.

typedef struct {
  real         addr_coverage;
  real         data_coverage;
  int unsigned addr_bins_hit;
  int unsigned data_bins_hit;
} coverage_state_t;

class coverage_collector;
  protected bit addr_hit[];
  protected bit data_hit[4];
  protected logic [31:0] base_addr;
  protected int unsigned addr_stride;

  function new(
    logic [31:0] base_addr = 32'h0000_0000,
    int unsigned num_addr_bins = 16,
    int unsigned addr_stride = 4
  );
    this.base_addr   = base_addr;
    this.addr_stride = (addr_stride == 0) ? 4 : addr_stride;
    this.addr_hit    = new[num_addr_bins];
    reset();
  endfunction

  function void reset();
    foreach (addr_hit[i]) begin
      addr_hit[i] = 0;
    end

    foreach (data_hit[i]) begin
      data_hit[i] = 0;
    end
  endfunction

  function void sample_address(logic [31:0] addr);
    int unsigned bin_idx;

    if (addr < base_addr) begin
      return;
    end

    bin_idx = (addr - base_addr) / addr_stride;
    if (bin_idx < addr_hit.size()) begin
      addr_hit[bin_idx] = 1;
    end
  endfunction

  function void sample_data(logic [31:0] data);
    case (data)
      32'h0000_0000: data_hit[0] = 1;
      32'hFFFF_FFFF: data_hit[1] = 1;
      32'hAAAA_AAAA: data_hit[2] = 1;
      32'h5555_5555: data_hit[3] = 1;
      default: begin
      end
    endcase
  endfunction

  function void sample_transaction(logic [31:0] addr, logic [31:0] data);
    sample_address(addr);
    sample_data(data);
  endfunction

  function int unsigned get_addr_bins_hit();
    int unsigned count;

    count = 0;
    foreach (addr_hit[i]) begin
      if (addr_hit[i]) begin
        count++;
      end
    end

    return count;
  endfunction

  function int unsigned get_data_bins_hit();
    int unsigned count;

    count = 0;
    foreach (data_hit[i]) begin
      if (data_hit[i]) begin
        count++;
      end
    end

    return count;
  endfunction

  function coverage_state_t get_coverage_state();
    coverage_state_t state;

    state.addr_bins_hit = get_addr_bins_hit();
    state.data_bins_hit = get_data_bins_hit();
    state.addr_coverage = (addr_hit.size() == 0) ? 1.0 :
                          real'(state.addr_bins_hit) / real'(addr_hit.size());
    state.data_coverage = real'(state.data_bins_hit) / 4.0;

    return state;
  endfunction

  function logic [31:0] get_uncovered_address();
    int unsigned uncovered_bins[$];

    if (addr_hit.size() == 0) begin
      return base_addr;
    end

    foreach (addr_hit[i]) begin
      if (!addr_hit[i]) begin
        uncovered_bins.push_back(i);
      end
    end

    if (uncovered_bins.size() == 0) begin
      return base_addr + (addr_stride * $urandom_range(addr_hit.size() - 1, 0));
    end

    return base_addr +
           (addr_stride * uncovered_bins[$urandom_range(uncovered_bins.size() - 1, 0)]);
  endfunction

  function logic [31:0] get_uncovered_data();
    int unsigned missing_patterns[$];

    foreach (data_hit[i]) begin
      if (!data_hit[i]) begin
        missing_patterns.push_back(i);
      end
    end

    if (missing_patterns.size() == 0) begin
      return $urandom();
    end

    case (missing_patterns[$urandom_range(missing_patterns.size() - 1, 0)])
      0: return 32'h0000_0000;
      1: return 32'hFFFF_FFFF;
      2: return 32'hAAAA_AAAA;
      default: return 32'h5555_5555;
    endcase
  endfunction
endclass

class coverage_driven_address_strategy extends address_strategy;
  `uvm_object_utils(coverage_driven_address_strategy)

  coverage_collector cov;
  real addr_goal = 0.80;

  function new(string name = "coverage_driven_address_strategy");
    super.new(name);
  endfunction

  virtual function logic [31:0] next_address();
    coverage_state_t cov_state;
    logic [31:0] addr;

    if (cov == null) begin
      void'(std::randomize(addr) with {
        addr[1:0] == 2'b00;
      });
      return addr;
    end

    cov_state = cov.get_coverage_state();
    if (cov_state.addr_coverage < addr_goal) begin
      return cov.get_uncovered_address();
    end

    void'(std::randomize(addr) with {
      addr[1:0] == 2'b00;
    });
    return addr;
  endfunction

  virtual function void record_transaction(logic [31:0] addr, logic [31:0] data);
    if (cov != null) begin
      cov.sample_transaction(addr, data);
    end
  endfunction

  virtual function void reset();
    if (cov != null) begin
      cov.reset();
    end
  endfunction
endclass

class coverage_driven_write_sequence extends flexible_write_sequence;
  `uvm_object_utils(coverage_driven_write_sequence)

  coverage_collector cov;
  real data_goal = 0.90;

  function new(string name = "coverage_driven_write_sequence");
    super.new(name);
  endfunction

  virtual task body();
    write_transaction req;
    coverage_driven_address_strategy cov_strategy;
    coverage_state_t cov_state;

    if (cov == null) begin
      cov = new();
    end

    if (addr_strategy == null) begin
      cov_strategy = coverage_driven_address_strategy::type_id::create("cov_strategy");
      cov_strategy.cov = cov;
      addr_strategy = cov_strategy;
    end
    else if ($cast(cov_strategy, addr_strategy)) begin
      cov_strategy.cov = cov;
    end

    for (int i = 0; i < num_transactions; i++) begin
      req = write_transaction::type_id::create($sformatf("req_%0d", i));
      req.addr = addr_strategy.next_address();

      cov_state = cov.get_coverage_state();
      if (cov_state.data_coverage < data_goal) begin
        req.data = cov.get_uncovered_data();
      end
      else begin
        req.data = $urandom();
      end

      start_item(req);
      finish_item(req);

      cov.sample_transaction(req.addr, req.data);
    end

    cov_state = cov.get_coverage_state();
    `uvm_info(
      get_type_name(),
      $sformatf(
        "Coverage-driven sequence complete: addr=%0.1f%% data=%0.1f%%",
        cov_state.addr_coverage * 100.0,
        cov_state.data_coverage * 100.0
      ),
      UVM_LOW
    )
  endtask
endclass

/*
  Cache Proxy DUT (RTL)
  - Direct-mapped cache
  - Write-allocate + write-through
  - Single-cycle request accept, single-cycle response
*/
module cache_proxy_dut #(
  parameter int unsigned LINES = 8,
  parameter int unsigned WORDS_PER_LINE = 4,
  parameter int unsigned MEM_WORDS = 1024
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        req_valid,
  input  logic        req_write,
  input  logic [31:0] req_addr,
  input  logic [31:0] req_wdata,
  output logic        req_ready,
  output logic        rsp_valid,
  output logic [31:0] rsp_rdata
);

  // Cache storage
  logic        valid   [0:LINES-1];
  int unsigned tag_arr [0:LINES-1];
  logic [31:0] data_arr[0:LINES-1][0:WORDS_PER_LINE-1];

  // Main memory storage
  logic [31:0] mem [0:MEM_WORDS-1];

  // Internal regs
  logic        req_valid_d;
  logic        req_write_d;
  logic [31:0] req_addr_d;
  logic [31:0] req_wdata_d;

  // Always ready (single outstanding request)
  assign req_ready = 1'b1;

  // Address decode helpers
  function automatic void decode_address(
    input  logic [31:0] address,
    output int unsigned index,
    output int unsigned tag,
    output int unsigned offset,
    output int unsigned word_addr
  );
    int unsigned line_addr;
    word_addr = address[31:2];
    line_addr = word_addr / WORDS_PER_LINE;
    index     = line_addr % LINES;
    tag       = line_addr / LINES;
    offset    = word_addr % WORDS_PER_LINE;
  endfunction

  function automatic int unsigned mem_index(input int unsigned word_addr);
    mem_index = word_addr % MEM_WORDS;
  endfunction

  // Capture request
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_valid_d <= 1'b0;
      req_write_d <= 1'b0;
      req_addr_d  <= '0;
      req_wdata_d <= '0;
    end else begin
      req_valid_d <= req_valid;
      req_write_d <= req_write;
      req_addr_d  <= req_addr;
      req_wdata_d <= req_wdata;
    end
  end

  // Initialize cache on reset
  integer i, j;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < LINES; i = i + 1) begin
        valid[i]   <= 1'b0;
        tag_arr[i] <= '0;
        for (j = 0; j < WORDS_PER_LINE; j = j + 1) begin
          data_arr[i][j] <= '0;
        end
      end
      rsp_valid <= 1'b0;
      rsp_rdata <= '0;
    end else begin
      rsp_valid <= 1'b0;
      rsp_rdata <= '0;

      if (req_valid_d) begin
        int unsigned index;
        int unsigned tag;
        int unsigned offset;
        int unsigned word_addr;
        int unsigned base_word;

        decode_address(req_addr_d, index, tag, offset, word_addr);

        if (valid[index] && tag_arr[index] == tag) begin
          // HIT
          if (req_write_d) begin
            data_arr[index][offset] <= req_wdata_d;
            mem[mem_index(word_addr)] <= req_wdata_d; // write-through
            rsp_rdata <= 32'h0;
          end else begin
            rsp_rdata <= data_arr[index][offset];
          end
        end else begin
          // MISS - fill line from memory
          base_word = (word_addr / WORDS_PER_LINE) * WORDS_PER_LINE;
          for (i = 0; i < WORDS_PER_LINE; i = i + 1) begin
            data_arr[index][i] <= mem[mem_index(base_word + i)];
          end
          valid[index]   <= 1'b1;
          tag_arr[index] <= tag;

          if (req_write_d) begin
            data_arr[index][offset] <= req_wdata_d;
            mem[mem_index(word_addr)] <= req_wdata_d;
            rsp_rdata <= 32'h0;
          end else begin
            rsp_rdata <= mem[mem_index(word_addr)];
          end
        end

        rsp_valid <= 1'b1;
      end
    end
  end
endmodule

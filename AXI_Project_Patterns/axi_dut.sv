module axi_dut (
  axi_if.dut dut_if
);
  always_ff @(posedge dut_if.clk or negedge dut_if.rstn) begin
    if (!dut_if.rstn) begin
      dut_if.awready <= 1'b1;
      dut_if.wready  <= 1'b1;
      dut_if.bresp   <= 2'b00;
      dut_if.bvalid  <= 1'b0;
      dut_if.arready <= 1'b1;
      dut_if.rdata   <= 32'h0;
      dut_if.rresp   <= 2'b00;
      dut_if.rvalid  <= 1'b0;
      dut_if.rlast   <= 1'b0;
    end else begin
      if (dut_if.awvalid) begin
        dut_if.awready <= 1'b1;
      end
      if (dut_if.wvalid) begin
        dut_if.wready <= 1'b1;
        dut_if.bresp  <= (dut_if.wdata[0] ? 2'b10 : 2'b00);
        dut_if.bvalid <= 1'b1;
      end else if (dut_if.bready) begin
        dut_if.bvalid <= 1'b0;
      end
    end
  end
endmodule

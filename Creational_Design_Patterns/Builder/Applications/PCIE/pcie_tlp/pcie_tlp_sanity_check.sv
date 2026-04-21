// pcie_tlp_sanity_seq.sv
class pcie_tlp_sanity_seq extends uvm_sequence #(pcie_tlp_item);
`uvm_object_utils(pcie_tlp_sanity_seq)

function new(string name = "pcie_tlp_sanity_seq");
  super.new(name);
endfunction

task body();
  pcie_tlp_item tlp;

  // Create a Memory Write TLP (3DW + Data)
  tlp = pcie_tlp_item::type_id::create("tlp");
  start_item(tlp);
  assert(tlp.randomize() with {
    fmt_type == 8'h0;        // Memory Write, 32-bit address
    address  == 32'h1000_0000;
    data.size() == 1;
    data[0] == 32'hDEADBEEF;
    requester_id == 16'h0010; // RC BDF
    completer_id == 16'h0100; // EP BDF
  });
  finish_item(tlp);

  `uvm_info(get_full_name(), $sformatf("Sent TLP: %s", tlp.convert2string()), UVM_LOW)
endtask
endclass
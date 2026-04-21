// pcie_dllp_item.sv
class pcie_dllp_item extends uvm_sequence_item;
typedef enum {
  DLLP_ACK,
  DLLP_NAK,
  DLLP_FLOW_CONTROL_UPDATE,
  DLLP_POWER_MANAGEMENT
} dllp_type_e;

rand dllp_type_e type;
rand bit [11:0] ack_nak_seq_num;      // For ACK/NAK
rand bit [31:0] fc_data;              // For FC Update (header + data credit)

`uvm_object_utils_begin(pcie_dllp_item)
  `uvm_field_enum(dllp_type_e, type, UVM_DEFAULT)
  `uvm_field_int(ack_nak_seq_num, UVM_HEX)
  `uvm_field_int(fc_data, UVM_HEX)
`uvm_object_utils_end

function new(string name = "pcie_dllp_item");
  super.new();
endfunction

function string convert2string();
  case (type)
    DLLP_ACK: return $sformatf("ACK Seq=%0h", ack_nak_seq_num);
    DLLP_NAK: return $sformatf("NAK Seq=%0h", ack_nak_seq_num);
    DLLP_FLOW_CONTROL_UPDATE: return $sformatf("FC Update=0x%0h", fc_data);
    DLLP_POWER_MANAGEMENT: return "PM DLLP";
    default: return "Unknown DLLP";
  endcase
endfunction
endclass
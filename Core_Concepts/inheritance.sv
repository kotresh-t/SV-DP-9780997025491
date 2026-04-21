/* Results: 
# AXI Txn: addr=0x1000, data=0xa5a5 time = 0
# AXI Txn: addr=0x2000, data=0x5a5a, delay=5 time = 5
*/ 

module tb(); 

// Base transaction
class axi_txn;
bit [31:0] addr;
bit [31:0] data;

    function void display();
        $display("AXI Txn: addr=0x%0h, data=0x%0h time = %0d", addr, data,$time);
    endfunction
endclass

// Extended version with delay
class axi_txn_with_delay extends axi_txn;
int delay_cycles;

    function void display();
        $display("AXI Txn: addr=0x%0h, data=0x%0h, delay=%0d time = %0d", addr, data, delay_cycles,$time);
    endfunction
endclass

axi_txn txn1; 
axi_txn_with_delay txn2; 

initial
begin 
    txn1 = new();
    txn1.addr = 32'h1000;
    txn1.data = 32'hA5A5;

    txn2 = new();
    txn2.addr = 32'h2000;
    txn2.data = 32'h5A5A;
    txn2.delay_cycles = 5;

    txn1.display(); // No delayay
    #txn2.delay_cycles; 
    txn2.display(); // With delay
    
    #100 $finish; 
end

endmodule
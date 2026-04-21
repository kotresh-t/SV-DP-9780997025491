// Abstract base class for transactions
abstract class TransactionStrategy;
    // Setup the transaction
    function void setup(bit [31:0] addr, bit [31:0] data);
    
    // Execute the transaction
    virtual task execute();
    
    // Get address (for routing purposes)
    virtual function bit [31:0] get_address();
    
    // Get data (this could be the written data or a dummy return in case of a read transaction)
    virtual function bit [31:0] get_data();
endclass

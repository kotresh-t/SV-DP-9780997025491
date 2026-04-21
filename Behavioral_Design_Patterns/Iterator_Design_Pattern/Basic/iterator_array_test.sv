// Iterator Design Pattern - Simple Example in SystemVerilog
// Without Composition of Objects
// Test module
module iterator_test;
// Iterator Interface/Class
class Iterator;
    virtual function bit hasNext();
    endfunction
    
    virtual function int getNext();
    endfunction
endclass

// Concrete Iterator for Array
class ArrayIterator extends Iterator;
    local int data[];
    local int index;
    
    function new(int arr[]);
        data = arr;
        index = 0;
    endfunction
    
    virtual function bit hasNext();
        return (index < data.size());
    endfunction
    
    virtual function int getNext();
        if (hasNext()) begin
            return data[index++];
        end else begin
            return -1; // Error value
        end
    endfunction
endclass


    initial begin
        static int numbers[] = '{10, 20, 30, 40, 50};
        Iterator iter;
        ArrayIterator ArrayIterator; 
        int value;
        ArrayIterator = new(numbers); 
        // Create iterator
        iter = ArrayIterator;
        
        // Iterate through collection
        $display("Iterator Design Pattern Example:");
        $display("================================");
        while (iter.hasNext()) begin
            value = iter.getNext();
            $display("Value: %0d", value);
        end
        
        $display("================================");
        $display("Iteration completed successfully!");
        $finish;
    end
endmodule

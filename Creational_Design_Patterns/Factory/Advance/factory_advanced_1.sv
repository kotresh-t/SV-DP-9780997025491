
module test(); 
typedef class Factory; 

class Base;
    static Base b;

    // Nested type_id structure
    class type_id;
        // Static method for creating an instance
        static function Base create();
            string typename = get_typename(); // Get the class type name
            b = Factory::create(typename); // Create object based on type name
            return b;
        endfunction
    endclass

    // Base class display method
    virtual function void display();
        $display("Base class display");
    endfunction

    // Method to get the class type name (reflection-like behavior)
    virtual protected function string get_typename();
        return "Base";
    endfunction
endclass

class DerivedA extends Base;
    function void display();
        $display("DerivedA class display");
    endfunction

    protected function string get_typename();
        return "DerivedA";
    endfunction
endclass

class DerivedB extends Base;
    function void display();
        $display("DerivedB class display");
    endfunction

    protected function string get_typename();
        return "DerivedB";
    endfunction
endclass

class Factory;
	DerivedA d_a=new(); 
	DerivedB d_b=new(); 

    static function Base create(string typename);
        Base obj;
        if (typename == "DerivedA") begin
	    obj = d_a;
        end else if (typename == "DerivedB") begin
            obj = d_b;
        end else begin
            obj = new();
        end
        return obj;
    endfunction
endclass

initial begin
    Base obj;
    Base objA;
    Base objB;

    // Creating instances using the type_id::create method
    obj = Base::type_id::create();
    obj.display(); // Displays: Base class display

    objA = DerivedA::type_id::create();
    objA.display(); // Displays: DerivedA class display

    objB = DerivedB::type_id::create();
    objB.display(); // Displays: DerivedB class display
end

endmodule // test
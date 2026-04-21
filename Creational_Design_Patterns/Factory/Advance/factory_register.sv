/* This example demonstrates Simple Factory registration mechanism in SystemVerilog. 
 * We have a base class 'Base' with a virtual method 'create' that is overridden by derived classes 'DerivedA' and 'DerivedB' to create instances of themselves.
 * We have a 'Factory' class that maintains a registry of class handles for the derived classes in registry method. 
 * The factory can create instances of the registered classes based on a string identifier.
*/ 
module test(); 

class Base;
    Base b; 

    // Virtual method for creating an instance
    virtual function Base create();
	b = new;
	return b; 
    endfunction

    // Base class display method
    virtual function void display();
        $display("Base class display");
    endfunction
endclass


class DerivedA extends Base;
    static DerivedA type_id; // Static instance for factory registration

    // Override the creation method
    virtual function Base create();
        b = new();
	$cast(type_id, b); 
	return b; 
    endfunction

    // Display method specific to DerivedA
    virtual function void display();
        $display("DerivedA class display");
    endfunction
endclass
//DerivedA::type_id = new; // Initialize the static instance

class DerivedB extends Base;
    static DerivedB type_id; // Static instance for factory registration

    // Override the creation method
    virtual function Base create();
        b = new();
	$cast(b,type_id); 
	return b; 
    endfunction

    // Display method specific to DerivedB
    virtual function void display();
        $display("DerivedB class display");
    endfunction
endclass
//DerivedB::type_id = new; // Initialize the static instance


class Factory;
    static protected Base class_handles[string];

    static function void register(string name, Base class_handle);
        class_handles[name] = class_handle;
    endfunction

    static function Base create(string name);
        if (class_handles.exists(name)) begin
            return class_handles[name];
        end else begin
            $error("Class type %s not registered in the factory", name);
            return null;
        end
    endfunction
endclass

initial begin
    Factory::register("DerivedA", DerivedA::type_id);
    Factory::register("DerivedB", DerivedB::type_id);
end


initial begin
    DerivedA obj;

    // Create an instance of DerivedA
    obj = DerivedA::type_id::create("obj");
    obj.display(); // Displays: DerivedA class display

    //// Create an instance of DerivedB
    //obj = Factory::create("DerivedB");
    //obj.display(); // Displays: DerivedB class display
end

endmodule 


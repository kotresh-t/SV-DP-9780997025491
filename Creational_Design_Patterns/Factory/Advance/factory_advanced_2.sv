/* This example demonstrates the Factory Design Pattern in SystemVerilog and usage in UVM Framework with macro based expansion for class registration.
* It extends from factory_advanced_uvm.sv example and uses macro to define the type_id class and create method for each class that needs to be registered in the factory.
* The macro `UVM_OBJECT_UTILS(TYPE) is defined to generate the type_id class
*/ 

module test(); 
typedef class Factory; 

`define UVM_OBJECT_UTILS(TYPE) \
class type_id; \
    static function string get_typename(); \
        return `"TYPE`"; \
    endfunction \
    static function Base create(); \
    	string type_name; \
    	type_name =  get_typename(); \
        b 	  = Factory::create(type_name); \
        return b; \
    endfunction \
endclass 


class Base;
    static Base b;

   `UVM_OBJECT_UTILS(Base)  

    // Base class display method
    virtual function void display();
        $display("Base class display");
    endfunction
endclass

class DerivedA extends Base;

    `UVM_OBJECT_UTILS(DerivedA) 
    function void display();
        $display("DerivedA class display");
    endfunction

endclass

class DerivedB extends Base;
    `UVM_OBJECT_UTILS(DerivedB) 
    
    function void display();
        $display("DerivedB class display");
    endfunction
endclass

class Factory;
     static	DerivedA d_a=new(); 
     static	DerivedB d_b=new(); 

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

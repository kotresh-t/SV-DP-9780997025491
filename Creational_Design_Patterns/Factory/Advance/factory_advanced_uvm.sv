/* This example demonstrates the Factory Design Pattern in SystemVerilog and usage in UVM Framework. 
*  Generic Base class provides a creation of objects based on the type of the object needs to be created.
*  Factory class has a static method that takes a string input to determine which object to create and return.
*/ 
module test;
typedef class Factory; 

class Base;
    static Base b; 

    // Nested type_id structure
    class type_id;
        // Static method for creating an instance
        static function Base create(string name);
		b=Factory::create(name); 
		return b; 
        endfunction
    endclass

    // Base class display method
    virtual function void display();
        $display("Base class display");
    endfunction
endclass


class Base_A extends Base; 
    // Base class display method
    virtual function void display();
        $display("Extended Base class display");
    endfunction
endclass 

class Factory; 
	static Base_A b_a=new(); 

	static function Base create(string name="Base"); 
		Base obj;
		if(name == "Base_A") begin
			obj = b_a; 
		end

		return obj; 
	endfunction 
endclass //Factory

initial
begin 
	Base obj; 
	Base_A obj_a; 

	obj = Base_A::type_id::create("Base_A"); 
	obj.display(); 

end


endmodule 

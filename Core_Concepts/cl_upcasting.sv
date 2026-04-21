/* 
The casting in the first example is redundant as the child already have the variable a, as it inherits all properties of the base class. So, if the casting wasn't done, still the access of child_h.a is valid. 
But in the second example, the variable b is declared as virtual in the base class and overridden in the child class. So, when we access b using the base class handle, it will call the child class's version of b due 
to polymorphism. This is why upcasting is used in the second example to demonstrate polymorphism, while in the first example, it is not necessary for accessing variable a.
Upcasting is basically  used to access the base class methods, where you want to access base class methods using the variable of the superclass. Below example will clarify the idea:
*/ 

class BasePacket;
  int A = 1;
  int B = 2;

  virtual function void printA;
    $display("BasePacket::A is %d", A);
  endfunction : printA
  
  virtual function void printB;
    $display("BasePacket::B is %d", B);
  endfunction : printB

endclass : BasePacket
 
class My_Packet extends BasePacket;
  int A = 3;
  int B = 4;

  virtual function void printA;
    $display("My_Packet::A is %d", A);
  endfunction: printA

  virtual function void printB;
    $display("My_Packet::B is %d", B);
  endfunction : printB

endclass : My_Packet
 
module main;
  BasePacket P1;
  My_Packet P2 ; 

// In this example Variable A is still downcasted while Variable B is upcasted
// due to virtual method being used in class My_Packet. 
// In simple words Downcasting represents inheritance and Upcasting represents Polymorphism.

initial begin
  P1 = new; // P1 is a handle to a BasePacket object
  P2 = new; // P2 is a handle to a My_Packet object
	P1.printA; // displays 'BasePacket::A is 1'
	P1.printB; // displays 'BasePacket::B is 2'
	$cast(P1,P2) ;// same as P1 = P2..  P1 has a handle to a My_packet object, 
  // Try with $cast(P2,P1). This will not work because P2 is a handle to a My_Packet object and cannot be cast to a BasePacket object. This will result in a runtime error.
  // P2=P1; This will also not work because P2 is a handle to a My_Packet object and cannot be assigned a BasePacket object. This will result in a compile-time error.
	P1.printA; // displays 'BasePacket::A is 1'
	P1.printB; // displays 'My_Packet::B is 4' – latest derived method
	P2.printA; // displays 'My_Packet::A is 3'
	P2.printB; // displays 'My_Packet::B is 4'
end
endmodule: main

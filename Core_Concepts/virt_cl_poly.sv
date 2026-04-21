/* 
 * This file demonstrates virtual classes and polymorphism in SystemVerilog.
 * We have a virtual base class 'sports_coupe' with a virtual method 'print'. The virtual class doesn't have implementation for 'print' and serves as an interface for derived classes.
 * The derived classes 'KCMotors_H10' and 'JRSports_M8' override the 'print' method to display specific information about the car.
 * We create an array of 'sports_coupe' objects, populate it with instances of the derived classes, and call the 'print' method to demonstrate polymorphism.
 */

module top;

typedef enum {RED, BLUE, BLACK, WHITE} color_t;

virtual class sports_coupe;  // note that car is a virtual class
  rand color_t color;
  virtual function void print();
    $display("I'm a %s sports car", color.name());
  endfunction : print
endclass : sports_coupe

class KCMotors_H10 extends sports_coupe;
  virtual function void print();
    $display("I'm a %s KCMotors_H10", color.name());
  endfunction : print
endclass : KCMotors_H10

class JRSports_M8 extends sports_coupe;
  virtual function void print();
    $display("I'm a %s JRSports_M8", color.name());
  endfunction : print
endclass : JRSports_M8

 sports_coupe cars[]; 
 KCMotors_H10 p1, p2;
 JRSports_M8 f1, f2;

 initial begin
   cars = new[4];
   p1 = new(); p2 = new();
   void'(p1.randomize());
   void'(p2.randomize());
   f1 = new(); f2 = new();
   void'(f1.randomize());
   void'(f2.randomize());
   $cast(cars[0], p1);
   $cast(cars[1], f1);
   $cast(cars[2], p2);
   $cast(cars[3], f2);
   print_all(cars);
 end

 task print_all(sports_coupe cars[]);
   for (int i=0; i<cars.size(); i++)
     cars[i].print();
 endtask : print_all

endmodule : top

/* Results: 
# I'm a BLACK KCMotors_H10
# I'm a BLUE JRSports_M8
# I'm a BLACK KCMotors_H10
# I'm a WHITE JRSports_M8
*/

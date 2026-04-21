module lazy_singleton_test(); 

class lazy_singleton;
  // The instance is created immediately when the static variable is defined
  static local lazy_singleton inst = null;

  // Private constructor
  local function new();
  endfunction

  // Static method to return the pre-created instance
  static function lazy_singleton get_inst();
    if (inst == null) begin
      inst = new();
    end
    return inst;
  endfunction
  
  function void display();
    $display("lazy Singleton accessed.");
  endfunction
endclass

lazy_singleton s1, s2;
initial begin
  s1 = lazy_singleton::get_inst();
  s2 = lazy_singleton::get_inst();
  s1 = lazy_singleton::get_inst();
  if (s1 == s2) begin
    $display("Both instances are the same. Singleton works!");
  end else begin
    $display("Instances are different. Singleton failed.");
  end

  s1.display();
end // initial block

endmodule // lazy_singleton_test
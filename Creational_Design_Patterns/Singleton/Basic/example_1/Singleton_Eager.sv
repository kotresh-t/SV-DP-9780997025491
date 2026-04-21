module eager_singleton_test(); 

class eager_singleton;
  // The instance is created immediately when the static variable is defined
  static local eager_singleton inst = new();

  // Private constructor
  local function new();
  endfunction

  // Static method to return the pre-created instance
  static function eager_singleton get_inst();
    return inst;
  endfunction
  
  function void display();
    $display("Eager Singleton accessed.");
  endfunction
endclass

eager_singleton s1, s2;
initial begin
  s1 = eager_singleton::get_inst();
  s2 = eager_singleton::get_inst();
  s1 = eager_singleton::get_inst();
  if (s1 == s2) begin
    $display("Both instances are the same. Singleton works!");
  end else begin
    $display("Instances are different. Singleton failed.");
  end

  s1.display();
end // initial block

endmodule // eager_singleton_test
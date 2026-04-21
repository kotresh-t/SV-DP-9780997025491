/* This example demonstrates the Factory Design Pattern in SystemVerilog.
 * We have a base class 'driver' with a virtual method 'send_data'. 
 * We have specific driver implementations 'uart_driver' and 'spi_driver' that override the 'send_data' method to provide specific functionality.
 * The 'driver_factory' class has a static method 'create_driver' that takes a string input to determine which driver to create and return.
 * In the testbench, we get the driver type from user input, use the factory to create the appropriate driver, and then call the 'send_data' method on it.
 */
 
module test;

// Base class for all drivers
class driver;
  virtual function void send_data(logic data); endfunction
endclass

// Specific driver implementations
class uart_driver extends driver;
  function void send_data(logic data);
    // UART-specific data transmission logic
    $display("UART Driver Data"); 
  endfunction
endclass

class spi_driver extends driver;
  function void send_data(logic data);
    // SPI-specific data transmission logic
    $display("SPI Driver Data"); 
  endfunction
endclass

// Factory class to create drivers
class driver_factory;

  static spi_driver spi_driver = new();  
  static uart_driver uart_driver = new(); 

  static function driver create_driver(string type_v);
    if (type_v == "uart") begin
      return uart_driver;
    end else if (type_v == "spi") begin
      return spi_driver;
    end else begin
      $error("Unsupported driver type: %s", type_v);
      return null;
    end
  endfunction
endclass


  driver my_driver;
  driver_factory factory;
  string driver_type ; 

  initial begin
    // Get driver type from user input
    driver_type  = $urandom(1)?"uart":"spi" ;

    // Create the specific driver using the factory
    my_driver = driver_factory::create_driver(driver_type);

    // Send data using the driver
    my_driver.send_data(123);
  end
endmodule

/* 
 * This file demonstrates downcasting in SystemVerilog.
 * We have a base class 'sensor' and several derived classes representing different types of sensors (temperature, humidity, pressure).
 * We create a list of sensors and use downcasting to identify the type of each sensor and call specific methods based on the type.
 * We also demonstrate a failed downcasting scenario where we attempt to cast a base class object to a derived class, which results in a runtime error.
 */
 
class sensor;
  string sensor_name;
  
  function new(string name);
    sensor_name = name;
  endfunction
  
  function void read_data();
    $display("Reading from sensor: %s", sensor_name);
  endfunction
endclass

class temperature_sensor extends sensor;
  real temperature;
  
  function new(string name);
    super.new(name);
  endfunction
  
  function void set_temperature(real temp);
    temperature = temp;
    $display("Temperature Sensor: %s - Set to %.2f°C", sensor_name, temperature);
  endfunction
endclass

class humidity_sensor extends sensor;
  real humidity;
  
  function new(string name);
    super.new(name);
  endfunction
  
  function void set_humidity(real humid);
    humidity = humid;
    $display("Humidity Sensor: %s - Set to %.2f%%", sensor_name, humidity);
  endfunction
endclass

class pressure_sensor extends sensor;
  real pressure;
  
  function new(string name);
    super.new(name);
  endfunction
  
  function void set_pressure(real pres);
    pressure = pres;
    $display("Pressure Sensor: %s - Set to %.2f kPa", sensor_name, pressure);
  endfunction
endclass

module test;

initial begin
   temperature_sensor temp_sensor,temp_sensor1;
   humidity_sensor humid_sensor;
   pressure_sensor pres_sensor;
   sensor sensor_list[$];
   sensor base_sensor;

   temperature_sensor temp_cast;
   humidity_sensor humid_cast;
   pressure_sensor pres_cast;
   
   temp_sensor = new("TMP36");
   humid_sensor = new("DHT11");
   pres_sensor = new("BMP280");
   
   // Add different sensors to the list
   sensor_list.push_back(temp_sensor);
   sensor_list.push_back(humid_sensor);
   sensor_list.push_back(pres_sensor);
   temp_sensor1 = new("LM35"); // Another temperature sensor
   sensor_list.push_back(temp_sensor1);  
   
   // Process all sensors
   foreach (sensor_list[i]) begin
     sensor_list[i].read_data();
     
     // Downcast to temperature sensor
     if($cast(temp_cast, sensor_list[i])) begin
       $display("  -> Detected: Temperature Sensor");
       temp_cast.set_temperature(25.5);
     end
     
     // Downcast to humidity sensor
     if($cast(humid_cast, sensor_list[i])) begin
       $display("  -> Detected: Humidity Sensor");
       humid_cast.set_humidity(60.0);
     end
     
     // Downcast to pressure sensor
     if($cast(pres_cast, sensor_list[i])) begin
       $display("  -> Detected: Pressure Sensor");
       pres_cast.set_pressure(101.325);
     end
     
     $display("");
   end
   
   // Demonstrate failed downcasting
   $display("--- Attempting to create and downcast base class ---"); 
   base_sensor  = new("Generic Sensor");
   
   if($cast(temp_cast, base_sensor))
     $display("Successfully cast to Temperature Sensor");
   else
     $display("Failed: Base sensor is not a Temperature Sensor");
   
   if($cast(humid_cast, base_sensor))
     $display("Successfully cast to Humidity Sensor");
   else
     $display("Failed: Base sensor is not a Humidity Sensor");

end
endmodule
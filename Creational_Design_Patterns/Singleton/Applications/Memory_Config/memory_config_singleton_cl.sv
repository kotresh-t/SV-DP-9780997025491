/*///////////////////////////////////////////////////////////////////////////////
//File Name	: MemoryConfigSingleton_cl.sv                                                                                          
//Description	: Creates a singleton class for shared memory config.                                                                              
//Args          :                                                                                           
//Author       	: Kotresh Ajjappa Tarale                                                
//Email         : tkotresh3@gmail.com                                           
///////////////////////////////////////////////////////////////////////////////*/


`ifndef MemoryConfigSingleton_SV
`define MemoryConfigSIngleton_SV

class MemoryConfigSingleton;

    local static MemoryConfigSingleton instance_cl;
    local static bit instance_created = 0;

    // Memory configuration parameters
    int memory_size;
    int access_time;

    // Local constructor
    local function new();
        // Default configuration
        memory_size = 1024; // 1K memory size
        access_time = 10;   // 10 ns access time
    endfunction

    // Public static method to get the instance
    static function MemoryConfigSingleton getInstance();
        if (instance_cl == null) begin
            if (instance_created) begin
                $error("Attempt to create multiple instances of MemoryConfigSingleton.");
            end
            instance_cl = new();
            instance_created = 1;
        end
        return instance_cl;
    endfunction

endclass // MemoryConfigSingleton

`endif // MemoryConfigSingleton_SV


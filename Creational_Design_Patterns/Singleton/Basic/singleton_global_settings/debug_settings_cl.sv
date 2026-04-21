class DebugSettingsSingleton;
    local static DebugSettingsSingleton debug_instance_priv;
    bit verbose_logging;
    bit mem_logging;
    bit trans_logging; 

    local function new();
        verbose_logging = 1; // Default: verbose logging enabled
	mem_logging	= 0; 
	trans_logging   = 0; 
    endfunction

    static function DebugSettingsSingleton getInstance();
        if (instance == null) begin
            debug_instance_priv = new();
        end
        return debug_instance_priv;
    endfunction
endclass


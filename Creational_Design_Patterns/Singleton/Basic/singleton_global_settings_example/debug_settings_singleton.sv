`ifndef DEBUG_SETTINGS_SINGLETON
`define DEBUG_SETTINGS_SINGLETON

class DebugSettingsSingleton;
    static DebugSettingsSingleton instance;
    bit verbose_logging;

    function new();
        verbose_logging = 1; // Default: verbose logging enabled
    endfunction

    static function DebugSettingsSingleton getInstance();
        if (instance == null) begin
            instance = new();
        end
        return instance;
    endfunction
endclass

`endif // DEBUG_SETTINGS_SINGLETON


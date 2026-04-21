`ifndef SIMULATION_PARAMETERS_SINGLETON
`define SIMULATION_PARAMETERS_SINGLETON

class SimulationParametersSingleton;
    static SimulationParametersSingleton instance;
    int simulation_time; // in nanoseconds

    function new();
        simulation_time = 1000; // Default value
    endfunction

    static function SimulationParametersSingleton getInstance();
        if (instance == null) begin
            instance = new();
        end
        return instance;
    endfunction
endclass

`endif // SIMULATION_PARAMETERS_SINGLETON

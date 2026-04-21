`ifndef FEATURE_TOGGLES_SINGLETON
`define FEATURE_TOGGLES_SINGLETON

class FeatureTogglesSingleton;
    static FeatureTogglesSingleton instance;
    bit enable_feature_a;
    bit enable_feature_b;

    function new();
        enable_feature_a = 1;
        enable_feature_b = 0;
    endfunction

    static function FeatureTogglesSingleton getInstance();
        if (instance == null) begin
            instance = new();
        end
        return instance;
    endfunction
endclass

`endif // FEATURE_TOGGLES_SINGLETON


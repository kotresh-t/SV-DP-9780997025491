
class FeatureTogglesSingleton;
    local static FeatureTogglesSingleton instance;
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


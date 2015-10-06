function filtered = filter_feature_by_scale(current_scales, feature)
%FILTER_FEATURE_BY_SCALE filters given features by a list of of given scales
%
%   Syntax:     filtered = filter_feature_by_scale(current_scales, feature)
%
%   Input:
%       current_scales - Vector of possible scales
%       feature        - feature struct
%
%   Output:
%       filtered       - logic vector

    filtered = ismember(feature.scales, current_scales);
end

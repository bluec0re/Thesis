function [unique_scales, scale_sizes] = get_available_scales(params, feature)
%GET_AVAILABLE_SCALES get the available scales by this feature struct
%
%   Syntax:     [unique_scales, scale_sizes] = get_available_scales(params, feature)
%
%   Input:
%       params  - Configuration struct
%       feature - feature struct
%
%   Output:
%       unique_scales - unique list of scales
%       scale_sizes   - amount of scales per split

    %unique_scales = unique(feature.scales);
    unique_scales = feature.all_scales;
    scale_sizes = size(unique_scales, 2) / params.codebook_scales_count;
end

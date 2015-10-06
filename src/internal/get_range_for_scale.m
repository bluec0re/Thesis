function [ min_size, max_size ] = get_range_for_scale(params, current_scales)
%GET_RANGE_FOR_SCALE get the range of given scales
%
%   Syntax:     [ min_size, max_size ] = get_range_for_scale(params, current_scales)
%
%   Input:
%       params - Configuration struct
%       current_scales - NxM matrix of scales
%
%   Output:
%       min_size - vector with N minimum values
%       max_size - vector with N maximum values

    % size of smallest feature
    orig_size = params.esvm_default_params.init_params.sbin * 5;

    num_scales = size(current_scales, 1);
    orig_size = repmat([orig_size, orig_size], num_scales, 1);
    min_size = repmat(max(current_scales, [], 2), 1, num_scales);
    max_size = repmat(min(current_scales, [], 2), 1, num_scales);
    min_size = round(orig_size ./ min_size);
    max_size = round(orig_size ./ max_size);
end

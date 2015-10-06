function in_scale = is_in_scale(params, min_size, max_size, requested_size)
%IS_IN_SCALE Tests if the requested sizes are within the a given scale
%
%   Syntax:     in_scale = is_in_scale(params, min_size, max_size, requested_size)
%
%   Input:
%       params - Configuration struct
%       min_size - lower bound (or [] if upper bound is requested)
%       max_size - upper bound (or [] if lower bound is requested)
%
%   Output:
%       in_scale - logic vector

    if isempty(params) || ~isfield(params, 'features_per_roi')
        features_per_roi = 2;
    else
        features_per_roi = params.features_per_roi;
    end

    if ~isempty(max_size)
        cur_size = max_size;
        in_scale = cur_size(1) >= requested_size(:, 1) / features_per_roi &&...
                   cur_size(2) >= requested_size(:, 2) / features_per_roi;
    else
        cur_size = min_size;
        in_scale = cur_size(1) <= requested_size(:, 1) / features_per_roi &&...
                   cur_size(2) <= requested_size(:, 2) / features_per_roi;
    end
end

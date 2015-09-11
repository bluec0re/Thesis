function in_scale = is_in_scale(params, min_size, max_size, requested_size)
%IS_ Summary of this function goes here
%   Detailed explanation goes here

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


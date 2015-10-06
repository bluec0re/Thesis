function current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes)
%GET_CURRENT_SCALES_BY_INDEX get the current scales by an index
%
%   Syntax:     current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes)
%
%   Input:
%       si            - index
%       unique_scales - available scales
%       scale_sizes   - amount of scales per split
%
%   Output:
%       current_scales - unique list of scales

    start_scale = round((si-1)*scale_sizes+1);
    end_scale = round(si*scale_sizes);
    current_scales = unique_scales(start_scale:end_scale);
end

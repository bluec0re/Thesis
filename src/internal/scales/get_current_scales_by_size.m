function current_scales = get_current_scales_by_size(params, unique_scales, scale_sizes, roi_size)
%GET_CURRENT_SCALES_BY_SIZE Summary of this function goes here
%   Detailed explanation goes here

    for si=1:params.codebook_scales_count
        current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes);
        [~, cur_size] = get_range_for_scale(params, current_scales);
        if is_in_scale(params, [], cur_size, roi_size)
            break;
        end
    end
end


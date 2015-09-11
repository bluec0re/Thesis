function current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes)
    start_scale = round((si-1)*scale_sizes+1);
    end_scale = round(si*scale_sizes);
    current_scales = unique_scales(start_scale:end_scale);
end
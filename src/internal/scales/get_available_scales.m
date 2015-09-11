function [unique_scales, scale_sizes] = get_available_scales(params, feature)
    %unique_scales = unique(feature.scales);
    unique_scales = feature.all_scales;
    scale_sizes = size(unique_scales, 2) / params.codebook_scales_count;
end
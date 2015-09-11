function filtered = filter_feature_by_scale(current_scales, feature)
    filtered = ismember(feature.scales, current_scales);
end
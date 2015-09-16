function filename = filter_cache_files(params, files, sizes, requested_size)
    % use scale set by number instead of patch sizes
    if length(requested_size) == 1
        filename = files{requested_size};
        return
    end

    for si=1:size(sizes, 1)
        cur_size = sizes(si, :);
        % ROI should consist of at least 2 features
        if is_in_scale(params, [], cur_size, requested_size)
            filename = files{si};
            info('--- Selected integrals up to %dx%d', cur_size(1), cur_size(2));
            return
        end
    end
    % last file as default
    filename = files{end};
end

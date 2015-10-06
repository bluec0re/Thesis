function filename = filter_cache_files(params, files, sizes, requested_size)
%FILTER_CACHE_FILES filters a list of cache files based on the best matching query size
%
%   Syntax:     filename = filter_cache_files(params, files, sizes, requested_size)
%
%   Input:
%       params         - Configuration struct
%       files          - list of possible files
%       sizes          - corresponding sizes
%       requested_size - size of query part
%
%   Output:
%       filename       - path of best matching file

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

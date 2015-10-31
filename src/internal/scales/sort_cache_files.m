function [files, sizes] = sort_cache_files(files, format)
%SORT_CACHE_FILES sort a list of cache files by sizes extracted by the given format
%
%   Syntax:     [files, sizes] = sort_cache_files(files, format)
%
%   Input:
%       files  - list of possible files
%       format - format string to extract the sizes
%
%   Output:
%       files - list of resorted files
%       sizes - list of extracted sizes
    if length(files) == 1
        sizes = [];
        return;
    end

    sizes = zeros([length(files), 2]);
    for fi=1:length(files)
        file = files{fi};
        current_size = sscanf(file, format);
        sizes(fi,:) = current_size;
    end
    [sizes, idx] = sortrows(sizes);
    files = files(idx);
end

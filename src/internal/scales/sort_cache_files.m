function [files, sizes] = sort_cache_files(files, format)
    sizes = zeros([length(files), 2]);
    for fi=1:length(files)
        file = files{fi};
        size = sscanf(file, format);
        sizes(fi,:) = size;
    end
    [sizes, idx] = sortrows(sizes);
    files = files(idx);
end
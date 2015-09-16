function [files, sizes] = sort_cache_files(files, format)
    sizes = zeros([length(files), 2]);
    for fi=1:length(files)
        file = files{fi};
        current_size = sscanf(file, format);
        sizes(fi,:) = current_size;
    end
    [sizes, idx] = sortrows(sizes);
    files = files(idx);
end

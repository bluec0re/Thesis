function array = alloc_struct_array( size, varargin )
%ALLOC_STRUCT_ARRAY Allocates a struct array of given size with given
%fields
%   Sorts fieldnames to be in line with matlabs save -struct
    
    if isempty(varargin)
        array(size) = struct;
    else
        % sort fieldnames
        sorted = sort(varargin);
        for ai=1:length(sorted)
            array(size).(sorted{ai}) = [];
        end
    end
end


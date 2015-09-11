function result = merge_structs(varargin)
%MERGE_STRUCTS Merges multiple structs together
%   Fields of the first struct gets overriden by the second, the third, ....
%
%   Syntax:     result = merge_structs(struct1, struct2, ...)
%
%   Input:
%       Multiple structs as arguments, at least 2
%
%   Output:
%       result - The merged struct

    if length(varargin) < 2
        error('At least 2 structs needed to join');
    end

    result = varargin{1};
    for si=2:length(varargin)
        next_struct = varargin{si};
        fields = fieldnames(next_struct);
        for fi=1:length(fields)
            result.(fields{fi}) = next_struct.(fields{fi});
        end
    end
end

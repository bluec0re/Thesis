function out = clean_struct(in, remove_fields)
%CLEAN_STRUCT Removes all fields which shouldn't be stored in a file
%
%   Syntax:     out = clean_struct(in, remove_fields)
%
%   Input:
%       in            - input struct
%       remove_fields - Additional field list to remove
%
%   Output:
%       out - resulting struct

    out = in;
    fields = fieldnames(in);
    for fi=1:length(fields)
        field = fields{fi};
        v = in.(field);
        if isstruct(v) || isa(v, 'function_handle') || iscell(v) || any(strcmp(field, remove_fields))
            out = rmfield(out, field);
        end
    end
end

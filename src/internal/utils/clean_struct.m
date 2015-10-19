function out = clean_struct(in, remove_fields)
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

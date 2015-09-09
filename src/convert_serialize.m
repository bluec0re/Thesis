function convert_serialize(filename)
%CONVERT_SERIALIZE Creates a corresponding file with toggled serialization
%
%   Syntax:     convert_serialize(filename)
%
%   Input:
%       filename - The file to invert
    [path, name, ext] = fileparts(filename);
    
    [data, serialized] = load_ex(filename);
    
    fields = fieldnames(data);
    for fi=1:length(fields)
        field = fields{fi};
        eval([field '=data.' field ';']);
        data = rmfield(data, field);
    end
    
    if serialized
        newfile = [path filesep name '_unser' ext];
        save_ex(newfile, '-noserialize', fields{:});
    else
        newfile = [path filesep name '_ser' ext];
        save_ex(newfile, '-serialize', fields{:});
    end
    
end


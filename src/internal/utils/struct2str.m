function str = struct2str(in, recursive)
%STRUCT2STR converts a struct into a printable string
%
%   Syntax:     str = struct2str(in, recursive)
%
%   Input:
%       in        - the struct to print
%       recursive - boolean to indicate a recursive print
%
%   Output:
%       str - String containing a text representation of the struct

    if ~exist('recursive', 'var')
        recursive = false;
    end

    str = '';

    fields = fieldnames(in);
    varlen = max(cellfun(@length, fields));

    if ~islogical(recursive)
        varlen = varlen + recursive;
    end

    fmt = ['%s%' num2str(varlen) 's: '];
    for fi=1:length(fields)
        field = fields{fi};
        str = sprintf(fmt, str, field);
        value = in.(field);
        if isstruct(value)
            if ~recursive
                value = sprintf('struct(%s)', strjoin(arrayfun(@(v)num2str(v), size(value), 'UniformOutput', false), 'x'));
            else
                value = sprintf('\n%s', struct2str(value, varlen));
            end
        elseif isnumeric(value)
            l = length(value);
            if l < 5
                value = num2str(value);
            else
                value = strjoin(arrayfun(@num2str, size(a), 'UniformOutput', false), 'x');
            end

            if l > 1
                value = sprintf('[%s]', value);
            end
        elseif islogical(value)
            if value
                value = 'true';
            else
                value = 'false';
            end
        elseif iscell(value)
            value = sprintf('{%s}', strjoin(arrayfun(@(v)num2str(v), size(value), 'UniformOutput', false), 'x'));
        elseif ischar(value)
            value = sprintf('''%s''', value);
        else
            value = class(value);
        end
        str = sprintf('%s%s\n', str, value);
    end

    str = str(1:end-1);
end

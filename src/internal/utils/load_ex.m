function [out, serialized] = load_ex( varargin )
%LOAD_EX Advanced load wrapper
%   Prints status information and allows to load files serialized with hlp_deserialize
%   Behaves exactly like matlabs load function
%
%   Syntax:     out = load_ex(filename, load_arg, ...)
%
%   Input:
%       filename - File to load
%       load_arg - Optional, variadic arguments for matlabs load function
%
%   Output:
%       out - optional struct containing the loaded variables
%       serialized - optional boolean indicating the load of a serialized var

    serialized = false;
    debg('Loading %s...', strrep(varargin{1}, '//', '/'), false);
    tmp = tic;
    if nargout > 0
        out = load(varargin{:});
        if size(out, 2) == 1 && isa(out, 'uint8')
            sec = toc(tmp);
            debg('%f sec. Deserializing...', sec, false);
            %tmp = tic;
            out = hlp_deserialize(out);
            serialized = true;
        end
    else
        vars = load(varargin{:});
        sec = toc(tmp);
        debg('%f sec. Deserializing...', sec, false, false);
        %tmp = tic;
        fields = fieldnames(vars);
        for ai=1:length(fields)
            arg = fields{ai};
            if size(vars.(arg), 2) == 1 && isa(vars.(arg), 'uint8')
                assignin('caller', arg, hlp_deserialize(vars.(arg)));
                serialized = true;
            else
                assignin('caller', arg, vars.(arg));
            end
            vars = rmfield(vars, arg);
        end
    end
    sec = toc(tmp);
    debg('DONE in %f sec', sec, false, true);
end

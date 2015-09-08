function out = load_ex( varargin )
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

    fprintf(1,'Loading %s...', varargin{1});
    tmp = tic;
    if nargout > 0
        out = load(varargin{:});
        if size(out, 2) == 1 && isa(out, 'uint8')
            sec = toc(tmp);
            fprintf('%f sec. Deserializing...', sec);
            %tmp = tic;
            out = hlp_deserialize(out);
        end
    else
        vars = load(varargin{:});
        sec = toc(tmp);
        fprintf('%f sec. Deserializing...', sec);
        %tmp = tic;
        fields = fieldnames(vars);
        for ai=1:length(fields)
            arg = fields{ai};
            if size(vars.(arg), 2) == 1 && isa(vars.(arg), 'uint8')
                assignin('caller', arg, hlp_deserialize(vars.(arg)));
            else
                assignin('caller', arg, vars.(arg));
            end
            rmfield(vars, arg);
        end
    end
    sec = toc(tmp);
    fprintf('DONE in %f sec\n', sec);
end

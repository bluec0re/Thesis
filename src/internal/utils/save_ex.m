function save_ex( varargin )
%SAVE_EX Advanced wrapper around save
%   Provides status information and to serialize the variables with hlp_serialize
%
%   Syntax:     save_ex(filename, save_args, ...)
%
%   Input:
%       filename - The file to save to
%       save_args - Variadic arguments for matlabs save function
%

    filepath = varargin{1};
    [path, ~, ~] = fileparts(filepath);
    if ~exist(path, 'dir')
        mkdir(path);
    end

    fprintf(' Serializing...');
    tmp = tic;
    for ai=1:nargin
        arg = varargin{ai};
        if ~strcmp(arg(1), '-') && ai > 1
            if false
                v = hlp_serialize(evalin('caller', arg));
            else
                v = evalin('caller', arg);
            end
            eval([arg '=v;']);
        end
    end
    sec = toc(tmp);
    fprintf('%f sec. Saving...', sec);

    tmp = tic;
    save(varargin{:});
    sec = toc(tmp);
    fprintf('DONE in %f sec\n', sec);
end

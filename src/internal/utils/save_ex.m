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
    
    [serialize, varargin] = should_serialize(varargin);
    fprintf(' Serializing...');
    tmp = tic;
    for ai=2:length(varargin)
        arg = varargin{ai};
        if ~strcmp(arg(1), '-')
            if serialize
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

function [serialize, new_args] = should_serialize(args)
    new_args{1} = args{1};
    serialize = false;
    for ai=2:length(args)
        arg = args{ai};
        if strcmp(arg, '-serialize')
            serialize = true;
        elseif strcmp(arg, '-noserialize')
            serialize = false;
        else
            new_args{end+1} = arg;
        end
    end
end
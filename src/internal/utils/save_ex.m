function save_ex( varargin )

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

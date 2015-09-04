function [ out ] = load_ex( varargin )
%LOAD_EX Summary of this function goes here
%   Detailed explanation goes here

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


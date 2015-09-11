function keywords = parse_keywords(input_args, allowed_keywords)
%PARSE_KEYWORDS Parses a list of arguments into a struct
%   Requires arguments of the form Keyword1, Value1, Keyword2, Value2, ...
%
%   Syntax:     keywords = parse_keywords(input_args, allowed_keywords)
%
%   Input:
%       input_args - Cell array of input arguments (e.g. varargin)
%       allowed_keywords - Optional cell array of allowed keywords
%
%   Output:
%       keywords - Struct of keyword, value pairs

    if mod(length(input_args), 2) ~= 0
        error('Number of arguments must be a multiple of 2');
    end

    input_args = reshape(input_args, 2, []);
    keywords = struct;
    for pair = input_args
        kw = lower(pair{1});
        if exist('allowed_keywords', 'var') && ~ismember(kw, allowed_keywords)
            error('Unknown keyword %s', kw);
        end
        keywords.(kw) = pair{2};
    end
end

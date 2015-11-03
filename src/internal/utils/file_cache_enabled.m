function [CACHE_FILE, params] = file_cache_enabled(params)
%FILE_CACHE_ENABLED Is the file cache enabled?
%
%   Syntax:     [CACHE_FILE, params] = file_cache_enabled(params)
%
%   Input:
%       params - Configuration
%   Output:
%       CACHE_FILE - True if data should be stored to a file
%       params     - Updated params struct if some fields are missing
    if ~isfield(params, 'dataset')
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    elseif isfield(params.dataset,'localdir') ...
          && ~isempty(params.dataset.localdir)
        CACHE_FILE = 1;
    else
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    end
end

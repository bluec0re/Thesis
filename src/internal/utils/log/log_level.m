function ll = log_level(varargin)
%LOG_LEVEL gets or sets the log level
%
%   Syntax:     ll = log_level([level])
%
%   Input:
%       level - optional log level to set
%
%   Output:
%       ll - current log level

    if length(varargin) == 1
        set_log_level(varargin{1});
    end
    ll = get_log_level();
end

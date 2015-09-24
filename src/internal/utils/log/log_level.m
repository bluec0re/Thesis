function ll = log_level( varargin )
%LOG_LEVEL Summary of this function goes here
%   Detailed explanation goes here

    if length(varargin) == 1
        set_log_level(varargin{1});
    end
    ll = get_log_level();
end


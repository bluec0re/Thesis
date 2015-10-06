function lvl = get_log_level()
%GET_LOG_LEVEL get current log level as string
%
%   Syntax:     lvl = get_log_level()
%
%   Output:
%       lvl - get the current log level

    if evalin('base', 'exist(''G_CURRENT_LOGLEVEL'', ''var'');')
        lvl = evalin('base', 'G_CURRENT_LOGLEVEL');
    elseif ~isempty(getCurrentTask())
        lvl = 'DEBUG';
    else
        lvl = 'INFO';
    end
end

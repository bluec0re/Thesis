function set_log_level(lvl)
%SET_LOG_LEVEL set current log level
%
%   Syntax:     set_log_level(lvl)
%
%   Input:
%       lvl - set the current log level

    levels = {'ERROR', 'DEBUG', 'INFO', 'WARNING'};
    levels = horzcat(levels, lower(levels));

    if any(strcmp(lvl, levels))
        assignin('base', 'G_CURRENT_LOGLEVEL', upper(lvl));
    else
        error('Invalid log level %s', lvl);
    end
end

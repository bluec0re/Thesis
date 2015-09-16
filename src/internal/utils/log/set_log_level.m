function set_log_level(lvl)
    levels = {'ERROR', 'DEBUG', 'INFO', 'WARNING'};
    levels = horzcat(levels, lower(levels));

    if any(strcmp(lvl, levels))
        assignin('base', 'G_CURRENT_LOGLEVEL', upper(lvl));
    else
        error('Invalid log level %s', lvl);
    end
end

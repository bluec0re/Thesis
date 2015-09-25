function lvl = get_log_level()
    if evalin('base', 'exist(''G_CURRENT_LOGLEVEL'', ''var'');')
        lvl = evalin('base', 'G_CURRENT_LOGLEVEL');
    else
        lvl = 'INFO';
    end
end
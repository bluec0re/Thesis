function info(fmt, varargin)
    if ~any(strcmp(get_log_level(), {'DEBUG', 'INFO'}))
        return;
    end

    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = '[\033[94mINFO\033[0m] %s';
    else
        newfmt = '[INFO] %s';
    end

    log_msg(newfmt, fmt, varargin{:});
end

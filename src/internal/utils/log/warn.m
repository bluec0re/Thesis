function warn(fmt, varargin)
    if ~any(strcmp(get_log_level(), {'DEBUG', 'INFO', 'WARNING'}))
        return;
    end

    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = '[\033[93mWARN\033[0m] %s';
    else
        newfmt = '[WARN] %s';
    end

    log_msg(newfmt, fmt, varargin{:});
end

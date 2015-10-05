function info(fmt, varargin)
    if ~any(strcmp(get_log_level(), {'DEBUG', 'INFO', 'WARNING', 'ERROR'}))
        return;
    end

    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = '[\033[91m ERR\033[0m] %s';
    else
        newfmt = '[ ERR] %s';
    end

    log_msg(newfmt, fmt, varargin{:});
end

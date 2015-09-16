function succ(fmt, varargin)
    if ~any(strcmp(get_log_level(), {'DEBUG', 'INFO'}))
        return;
    end

    if ~usejava('desktop') && ~isempty(getenv('TERM'))
        newfmt = '[\033[92mSUCC\033[0m] %s';
    else
        newfmt = '[SUCC] %s';
    end

    log_msg(newfmt, fmt, varargin{:});
end

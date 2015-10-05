function debg(fmt, varargin)
    if ~any(strcmp(get_log_level(), {'DEBUG'})) && false
        return;
    end

    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = '[\033[95mDEBG\033[0m] %s';
    else
        newfmt = '[DEBG] %s';
    end

    log_msg(newfmt, fmt, varargin{:});
end

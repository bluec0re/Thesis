function debg(fmt, varargin)
%DEBG log a debug message
%
%   Syntax:     debg(fmt, ..., [addprefix], [addnewline])
%
%   Input:
%       fmt        - Message to log. Formatting available
%       addprefix  - optional boolean to indicate if the prefix should be prepended
%       addnewline - optional boolean to indicate if a new line should be appended

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

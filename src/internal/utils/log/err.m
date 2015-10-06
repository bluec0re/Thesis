function err(fmt, varargin)
%ERR log a error message
%
%   Syntax:     err(fmt, ..., [addprefix], [addnewline])
%
%   Input:
%       fmt        - Message to log. Formatting available
%       addprefix  - optional boolean to indicate if the prefix should be prepended
%       addnewline - optional boolean to indicate if a new line should be appended

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

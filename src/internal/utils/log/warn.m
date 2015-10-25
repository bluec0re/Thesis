function warn(fmt, varargin)
%WARN log a warning message
%
%   Syntax:     warn(fmt, ..., [addprefix], [addnewline])
%
%   Input:
%       fmt        - Message to log. Formatting available
%       addprefix  - optional boolean to indicate if the prefix should be prepended
%       addnewline - optional boolean to indicate if a new line should be appended

    if ~any(strcmp(get_log_level(), {'DEBUG', 'INFO', 'WARNING'}))
        return;
    end

    w = warning('off', 'parallel:cluster:GetCurrentTaskFailed');
    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = '[\033[93mWARN\033[0m] %s';
    else
        newfmt = '[WARN] %s';
    end
    warning(w);

    log_msg(newfmt, fmt, varargin{:});
end

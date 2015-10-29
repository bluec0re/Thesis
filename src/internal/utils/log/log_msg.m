function log_msg(newfmt, fmt, varargin)
%LOG_MSG internal logging function
%
%   Syntax:     log_msg(newfmt, fmt, ..., [updateline], [addprefix], [addnewline])
%
%   Input:
%       newfmt     - Prefix format
%       fmt        - Message to log. Formatting available
%       updateline - optional boolean to indicate if the previous line should be overwritten
%       addprefix  - optional boolean to indicate if the prefix should be prepended
%       addnewline - optional boolean to indicate if a new line should be appended
    w = warning('off', 'parallel:cluster:GetCurrentTaskFailed');
    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = ['[\033[97m%s\033[0m] ' newfmt];
    else
        newfmt = ['[%s] ' newfmt];
    end
    warning(w);

    updateline = false;
    addprefix = true;
    addnewline = true;
    args = varargin;
    if length(varargin) > 0 && islogical(varargin{end})
        addnewline = varargin{end};
        args(end) = [];
    end

    if length(varargin) > 1 && islogical(varargin{end}) && islogical(varargin{end-1})
        addprefix = varargin{end-1};
        args(end) = [];
    end

    if length(varargin) > 2 && islogical(varargin{end}) && islogical(varargin{end-1}) && islogical(varargin{end-2})
        updateline = varargin{end-2};
        args(end) = [];
    end


    if addprefix
        fmt = sprintf(newfmt, char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')), fmt);
    end

    if addnewline
        fmt = [fmt '\n'];
    end

    if updateline
        fmt = ['\r' fmt];
    end

    fprintf(1, fmt, args{:});
    drawnow('update');

    try
        fp = fopen(log_file(), 'a');
        fprintf(fp, fmt, varargin{:});
        fclose(fp);
    catch
    end
end

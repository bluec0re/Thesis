function log_msg(newfmt, fmt, varargin)
%LOG_MSG internal logging function
%
%   Syntax:     log_msg(newfmt, fmt, ..., [addprefix], [addnewline])
%
%   Input:
%       newfmt     - Prefix format
%       fmt        - Message to log. Formatting available
%       addprefix  - optional boolean to indicate if the prefix should be prepended
%       addnewline - optional boolean to indicate if a new line should be appended

    if ~usejava('desktop') && ~isempty(getenv('TERM')) && isempty(getCurrentTask())
        newfmt = ['[\033[97m%s\033[0m] ' newfmt '\n'];
    else
        newfmt = ['[%s] ' newfmt '\n'];
    end

    if length(varargin) > 1 && islogical(varargin{end}) && islogical(varargin{end-1}) && varargin{end-1} == false
        % no prefix
        if varargin{end} == true
            fmt = [fmt '\n'];
        end
        varargin = varargin(1:end-2);
    else
        if ~isempty(varargin) && islogical(varargin{end}) && varargin{end} == false
            newfmt = newfmt(1:end-2);
            varargin = varargin(1:end-1);
        end

        fmt = sprintf(newfmt, char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')), fmt);
    end
    fprintf(1, fmt, varargin{:});

    try
        fp = fopen(log_file(), 'a');
        fprintf(fp, fmt, varargin{:});
        fclose(fp);
    catch
    end
end

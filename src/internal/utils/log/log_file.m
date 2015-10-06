function fname = log_file(varargin)
%LOG_FILE gets or sets the log file
%
%   Syntax:     fname = log_file([filename])
%
%   Input:
%       filename - optional filename to set
%
%   Output:
%       fname - current logfile

    fname = 'logfile.txt';

    if length(varargin) == 1
        assignin('base', 'G_LOG_FILE', varargin{1});
    end

    if evalin('base', 'exist(''G_LOG_FILE'', ''var'')')
        fname = evalin('base', 'G_LOG_FILE');
    end
end

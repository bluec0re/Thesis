function profile_stop( params )
%PROFILE_STOP Stops the profiling
%   Records the total execution time during the profiling
%
%   Syntax:     profile_stop( params )
%
%   Input:
%       params - The configuration struct processed by profile_start

    if ~isfield(params, 'profile')
        return;
    end
    total_time = toc(params.profile.start_time);
    cpu_total_time = cputime - params.profile.cpu_start_time;
    save(params.profile.file, 'total_time', 'cpu_total_time', '-append', '-v6'); 
end

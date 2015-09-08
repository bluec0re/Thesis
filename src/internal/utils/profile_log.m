function params = profile_log( params )
%PROFILE_STEP Logs an execution trace
%   Logs where it was called and which time elapsed since the profiling start
%
%   Syntax:     params = profile_log( params )
%
%   Input:
%       params - A configuration struct produced by profile_start
%
%   Output:
%       params - The input struct with updated profile.steps field (not required for subsequential calls)

    if ~isfield(params, 'profile')
        return;
    end

    cpu_elapsed = cputime - params.profile.cpu_start_time;
    elapsed = toc(params.profile.start_time);
    d = dbstack;
    caller = d(2);
    caller.elapsed = elapsed;
    caller.cpu_elapsed = cpu_elapsed;
    steps = load(params.profile.file, 'steps');
    steps = steps.steps;
    if isempty(steps) || isempty(fieldnames(steps))
        steps = caller;
    else
        steps(end+1) = caller;
    end
    params.profile.steps = steps;
    save(params.profile.file, 'steps', '-append', '-v6');
end

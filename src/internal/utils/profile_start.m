function params = profile_start( params )
%PROFILE_START Starts an execution trace
%   updates the given configuration struct by adding a profile field with subfields
%   records the start time.
%
%   Syntax:     params = profile_start( params )
%
%   Input:
%       params - A configuration struct with a configured dataset (dataset.localdir field is required)
%
%   Output:
%       params - The updated struct. Required for profile_log and profile_stop calls

    resultsdir = [params.dataset.localdir filesep 'profiling'];
    if ~exist(resultsdir, 'dir')
        mkdir(resultsdir);
    end
    profilefile = sprintf('%s/%s-%d-%d-%.3f-%d-%s.mat',...
        resultsdir, params.class, params.parts, params.clusters,...
        params.integrals_scale_factor, params.stream_max, params.codebook_type);

    start_time = tic;
    cpu_start_time = cputime;
    steps = struct([]);
    save(profilefile, 'params', 'start_time', 'cpu_start_time', 'steps', '-v6');
    params.profile.file = profilefile;
    params.profile.start_time = start_time;
    params.profile.cpu_start_time = cpu_start_time;

    profile_log(params);
end

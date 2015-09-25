function run_demo(skip_runs)
    addpath(genpath('src'));

    %stream_sizes = {10, 20, 50};
    %stream_sizes = {20, 50};
    stream_sizes = {100};
    query_src = {false, true};
    nonmax_type = {true, false};
    feature_per_roi = {2, 1.5, 1};
    %calibration = {true, false};
    calibration = {true};
    clusters = {1000, 512};
    files = {'2008_001566', '2008_000615', '2008_004363'};
    files = {'2008_001566', '2008_000615'};
    files = {'2008_004363'};
    integral_scales = {1, 0.75, 0.5};
    codebook_type = {'double', 'single'};
    libsvm_classification = {true};
%    libsvm_classification = {true, false};
    expand_bboxes = {true, false};

    total_runs = length(stream_sizes) * length(query_src) * length(nonmax_type)...
        * length(feature_per_roi) * length(calibration) * length(clusters)...
        * length(files) * length(integral_scales) * length(codebook_type)...
        * length(libsvm_classification) * length(expand_bboxes);

    current_run = 1;
    if ~exist('skip_runs', 'var')
        skip_runs = 0;
    end
    %clean = onCleanup(@() (profsave; fprintf(2, 'Last run: %d\n', evalin('caller', 'current_run'))));
    clean = onCleanup(@() profsave);
    profile on;
    for lc = libsvm_classification
        for cl = clusters
            for ss = stream_sizes
                for ct = codebook_type
                    for is = integral_scales
                        for fr = feature_per_roi
                            for f = files
                                for qs = query_src
                                    for nm = nonmax_type
                                        for c = calibration
                                            for eb = expand_bboxes
                                                msg = sprintf(['###################################\n'...
                                                         '## Run: %d/%d\n'...
                                                         '## Streamsize: %d\n'...
                                                         '## Query From Integral: %d\n'...
                                                         '## Nonmax Suppr Min: %d\n'...
                                                         '## Feature per ROI: %d\n'...
                                                         '## Calibration: %d\n'...
                                                         '## Clusters: %d\n'...
                                                         '## File: %s\n'...
                                                         '## Integral Scale: %d\n'...
                                                         '## Integral Type: %s\n'...
                                                         '## Libsvm classification: %d\n'...
                                                         '## Expand Boundingboxes: %d\n'...
                                                         '###################################\n'],...
                                                         current_run, total_runs, ss{1}, qs{1},...
                                                         nm{1}, fr{1}, c{1}, cl{1}, f{1}, is{1}, ...
                                                         ct{1}, lc{1}, eb{1});

                                                if skip_runs > 0
                                                    skip_runs = skip_runs - 1;
                                                    fprintf(msg);
                                                else
                                                    info(msg);
                                                    try
                                                        demo(false, 'stream_max', ss{1},...
                                                                    'query_from_integral', qs{1},...
                                                                    'nonmax_type_min', nm{1},...
                                                                    'features_per_roi', fr{1},...
                                                                    'use_calibration', c{1},...
                                                                    'clusters', cl{1},...
                                                                    'integrals_scale_factor', is{1},...
                                                                    'codebook_type', ct{1},...
                                                                    'use_libsvm_classification', lc{1},...
                                                                    'expand_bboxes', eb{1},...
                                                                    'default_query_file', f{1});

                                                        evalin('base', 'whos');
                                                    catch e
                                                        err('Exception %s', getReport(e));
                                                    end
                                                end

                                                current_run = current_run + 1;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    profile off;

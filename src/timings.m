
function timings(what)
    addpath(genpath('src'));
    addpath(genpath('vendors'));

    if strcmp(what, 'all')
        loading_timings();
        svm_timings();
    elseif strcmp(what, 'load')
        loading_timings();
    elseif strcmp(what, 'svm')
        svm_timings();
    elseif strcmp(what, 'extract')
        extract_timings();
    end
end

function loading_timings()
    types = {'naiive', 'sparse-kd', 'sparse-matlab', 'sparse-kd2', 'sparse-sum', 'sparse-overwrite'};
    clusters = {512, 1000};

    combinations = cardproduct(types, clusters);

    timings = zeros([1 length(p)]);
    for i=1:length(p)
        combi = combinations{i};
        cluster = combi{2};
        type = combi{1};
        timings(i) = load_db(cluster, type);
    end
    save_ex('results/timings/loading.mat', 'timings', 'combinations', '-v6');

    function elapsed = load_db(clusters, type)
        starttime = tic;
        load_ex(sprintf('results/models/codebooks/integrals/%s/%d--full-100-1.000-3-86x86.mat', type, clusters));
        elapsed = toc(starttime);
    end
end

function svm_timings()
    clusters = {512, 1000};
end

function [svm_models, windows, roi_size, database] = setup_extract(params, cluster, part)
    params.clusters = cluster;
    params.parts = part;

    pos = params.default_bounding_box;
    curid = params.default_query_file;

    roi_w = pos(3) - pos(1) + 1;
    roi_h = pos(4) - pos(2) + 1;

    query_file.I = curid;
    query_file.bbox = pos;
    query_file.cls = 'unknown';
    query_file.objectid = 1;
    query_file.curid = curid;

    query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size );
    neg_codebooks = get_neg_codebooks(params);
    svm_models = get_svms(params, query_codebooks, neg_codebooks);
    windows = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);

    cluster_model = generateCluster(params);
    database = load_database(params, cluster_model, roi_size);
end

function extract_timings()
    params = get_default_configuration();
    params.log_file = '/dev/null';

    % setup

    types = {'naiive', 'sparse-kd', 'sparse-matlab', 'sparse-kd2', 'sparse-sum', 'sparse-overwrite'};
    clusters = {512, 1000};
    parts = {1, 4};
    combinations = cardproduct(types, clusters, parts);

    timings = zeros([1 length(p)]);
    for i=1:length(p)
        combi = p{1};
        type = combi{1};
        cluster = combi{2};
        part = combi{3};

        [svm_models, windows, roi_size, database] = setup_extract(params, cluster, part);

        timings(i) = extract(params, type, cluster, roi_size, cluster_model, part);
    end
    save_ex('results/timings/extract.mat', 'timings', 'combinations', '-v6');

    function elapsed = extract(params, type, cluster, roi_size, database, parts)
        params.clusters = cluster;

        params.naiive_integral_backend = strcmp(type, 'naiive');
        params.use_kdtree = strcmp(type, 'sparse-kd') || strcmp(type, 'sparse-kd2');
        params.window_prefilter = strcmp(type, 'sparse-kd2');
        params.integral_backend_matlab_sparse = strcmp(type, 'sparse-matlab');
        params.integral_backend_sum = strcmp(type, 'sparse-sum');
        params.integral_backend_overwrite = strcmp(type, 'sparse-overwrite');

        [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, parts, svm_models);
    end
end

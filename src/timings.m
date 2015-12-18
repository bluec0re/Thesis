function timings(what, varargin)
% Most current testing script. Takes parameter to specify what should be tested
% and which data should be stored
    addpath(genpath('src'));
    addpath(genpath('vendors'));

    if strcmp(what, 'all')
        loading_timings();
        extract_timings();
    elseif strcmp(what, 'load')
        loading_timings();
    elseif strcmp(what, 'svm')
        svm_timings();
    elseif strcmp(what, 'extract')
        extract_timings();
    elseif strcmp(what, 'windows')
        window_performance();
    elseif strcmp(what, 'complete')
        skip_comb = 0;
        skip_scale = 0;
        force = false;
        if length(varargin) > 0
            skip_comb = varargin{1};
        end
        if length(varargin) > 1
            skip_scale = varargin{2};
        end
        if length(varargin) > 2
            force = varargin{3};
        end
        complete(skip_comb, skip_scale, force);
    end
end

function loading_timings()
% Measures loading times of different approaches
    types = {'sparse', 'sparse-kd', 'sparse-matlab', 'sparse-kd2', 'sparse-sum', 'sparse-overwrite', 'naiive'};
    clusters = {512, 1000};

    combinations = cartproduct(clusters, types);

    timings = zeros([1 length(combinations(:))]);
    filesizes = zeros([1 length(combinations(:))]);
    memsizes = zeros([1 length(combinations(:))]);
    if exist('results/timings/loading.mat', 'file')
        load_ex('results/timings/loading.mat');
    end
    for ic=1:length(combinations(:))
        if memsizes(ic) ~= 0
            info('Skipping %d: %d %f', ic, memsizes(ic), timings(ic));
            continue
        end
        combi = combinations{ic};
        cluster = combi{1};
        type = combi{2};

        [elapsed, filesize, memsize] = load_db(cluster, type);
        timings(ic) = elapsed;
        filesizes(ic) = filesize;
        memsizes(ic) = memsize;
        save_ex('results/timings/loading.mat', 'timings', 'combinations', 'filesizes', 'memsizes', '-v6');
    end

    function [elapsed, filesize, memsize] = load_db(clusters, type)
        %filepath = sprintf('results/models/codebooks/integral/%s/%d--full-database-100-1.000-double-3-86x86.mat', type, clusters);
        filepath = sprintf('results/models/codebooks/integral/%s/%d--full-database-100-1.000.mat', type, clusters);
        if ~exist(filepath, 'file')
            err('File %s missing', filepath);
            elapsed = 0;
            filesize = 0;
            memsize = 0;
            return;
        end
        starttime = tic;
        for i=1:10
            tmp = load_ex(filepath);
        end
        elapsed = toc(starttime) / 10
        filesize = dir(filepath);
        filesize = filesize.bytes
        s = whos('tmp');
        memsize = s.bytes
    end
end

function svm_timings()
% not used atm
    clusters = {512, 1000};
end

function [svm_models, windows, roi_size, database, cluster_model] = setup_extract(params, cluster, part)
% Setups the extraction of codebooks to measure it without loading and SVM training
    params.clusters = cluster;
    params.parts = part;

    pos = params.default_bounding_box;
    pos([3 4]) = pos([1 2]) + pos([3 4]) - 1;
    curid = params.default_query_file;

    roi_w = pos(3) - pos(1) + 1;
    roi_h = pos(4) - pos(2) + 1;
    roi_size = [roi_w, roi_h];

    query_file.I = get_image(params, curid);
    query_file.bbox = pos;
    query_file.cls = 'unknown';
    query_file.objectid = 1;
    query_file.curid = curid;

    cluster_model = generateCluster(params);
    query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size );
    neg_codebooks = get_neg_codebooks(params, cluster_model);
    svm_models = get_svms(params, query_codebooks, neg_codebooks);

    database = load_database(params, cluster_model, roi_size);

    sizes = {database.I_size};
    sizes = cell2mat(vertcat(sizes(:)));
    scale_factors = {database.scale_factor};
    scale_factors = cell2mat(vertcat(scale_factors(:)));
    max_w = max(sizes(:, 3) ./ scale_factors);
    max_h = max(sizes(:, 4) ./ scale_factors);

    windows = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
end

function extract_timings()
% Measures only the time needed to extract codebooks based on the configuration
    params = get_default_configuration();
    log_file('extract_timings.log');
    log_level('debug');
    params.memory_cache = true;
    params.use_threading = false;
    params.query_from_integral = true;


    % build different configurations
    types = {'sparse-kd', 'sparse-matlab', 'sparse-kd2', 'naiive', 'sparse-sum', 'sparse-overwrite'};
    clusters = {512, 1000};
    parts = {1, 4};
    window_scalings = {0, 5, 4, 3, 2, 1};
    window_scalings = {0};

    combinations = cartproduct(window_scalings, parts, clusters, types);
    num_comb = length(combinations(:));
    fprintf('Number combinations: %d\n', num_comb);

    skip = false([1 num_comb]);
    timings = zeros([1 num_comb]);
    num_windows = zeros([1 num_comb]);
    if exist('results/timings/database/extract.mat', 'file')
        orig = load_ex('results/timings/database/extract.mat');
        if length(orig.num_windows) == num_comb
            skip = orig.num_windows ~= 0;
            timings = orig.timings;
            num_windows = orig.num_windows;
        end
    end

    for ic=1:num_comb
        debg('%2d/%02d', ic, num_comb);
        if skip(ic)
            info('Skipping: %f %f', num_windows(ic), timings(ic));
            continue;
        end
        combi = combinations{ic};
        scaling = combi{1};
        part = combi{2};
        cluster = combi{3};
        type = combi{4};

        params.clusters = cluster;
        params.parts = part;
        params.naiive_integral_backend = strcmp(type, 'naiive');
        params.use_kdtree = strcmp(type, 'sparse-kd') || strcmp(type, 'sparse-kd2');
        params.window_prefilter = strcmp(type, 'sparse-kd2');
        params.integral_backend_matlab_sparse = strcmp(type, 'sparse-matlab');
        params.integral_backend_sum = strcmp(type, 'sparse-sum');
        params.integral_backend_overwrite = strcmp(type, 'sparse-overwrite');
        params.window_generation_relative_move = scaling;

        debg('Params:\n%s', struct2str(params));
        [svm_models, windows, roi_size, database, cluster_model] = setup_extract(params, cluster, part);
        num_windows(ic) = size(windows, 1);

        % Do the timing
        timings(ic) = extract(params, type, cluster, roi_size, database, part);
        save_ex('results/timings/database/extract.mat', 'timings', 'combinations', 'num_windows', '-v6');
    end

    function elapsed = extract(params, type, cluster, roi_size, database, parts)
        rounds = 5;
        starttime = tic;
        for i=1:rounds
            [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, parts, svm_models);
        end
        elapsed = toc(starttime)/rounds;
    end
end

function window_performance()
% compares only the differnt window sizes
    params = get_default_configuration();
    params.log_file = '/dev/null';
    params.memory_cache = false;
    params.use_threading = false;
    params.query_from_integral = true;

    pos = params.default_bounding_box;
    pos([3 4]) = pos([1 2]) + pos([3 4]) - 1;

    types = {'sparse-kd', 'sparse-kd2'};
    clusters = {512, 1000};
    parts = {1, 4};
    window_scalings = {0, 1, 2, 3, 4, 5};

    combinations = cartproduct(clusters, parts, types, window_scalings);
    num_comb = length(combinations(:));
    fprintf('Number combinations: %d\n', num_comb);

    results = cell([1 num_comb]);
    for ic=1:num_comb
        debg('%2d/%02d', ic, num_comb);
        combi = combinations{ic};
        cluster = combi{1};
        part = combi{2};
        type = combi{3};
        scaling = combi{4};

        params.clusters = cluster;
        params.parts = part;
        params.naiive_integral_backend = strcmp(type, 'naiive');
        params.use_kdtree = strcmp(type, 'sparse-kd') || strcmp(type, 'sparse-kd2');
        params.window_prefilter = strcmp(type, 'sparse-kd2');
        params.integral_backend_matlab_sparse = strcmp(type, 'sparse-matlab');
        params.integral_backend_sum = strcmp(type, 'sparse-sum');
        params.integral_backend_overwrite = strcmp(type, 'sparse-overwrite');
        params.window_generation_relative_move = scaling;

        debg('Params:\n%s', struct2str(params));
        [svm_models, windows, roi_size, database, cluster_model] = setup_extract(params, cluster, part);

        % Measure it
        results{ic} = do_work(params, svm_models, database, pos);
        save_ex('results/performance/windows.mat', 'results', 'combinations', '-v6');
    end

    function result = do_work(params, svm_models, database, pos)
        % makes a complete search & result generation
        [bboxes, codebooks, images] = extract_codebooks(params, svm_models, database, pos);
        scores = svm_models.classify(params, svm_models, codebooks);

        matches = true([1 length(scores)]);
        scores = scores(matches);
        mimg = images(matches);
        umimg = unique(mimg);
        mbbs = bboxes(matches, :);

        [scores, idx] = sort(scores, 'descend');
        mimg = mimg(idx);
        mbbs = round(mbbs(idx, :));
        result = struct;
        if ~isempty(scores)
            result = alloc_struct_array(length(scores), 'curid', 'query_curid', 'img', 'patch', 'score', 'bbox');
            result(length(scores)).query_curid = svm_models.curid;
        end

        scores2 = [];
        bbs2 = [];
        images2 = [];
        resnum = [];
        patches = [];
        numWindows = [];
        for ii=1:length(umimg)
            image = umimg(ii);

            image_only = find(mimg == image);
            I = get_image(params, database(image).curid);
            imax_w = size(I, 2);
            imax_h = size(I, 1);
            iobbs = mbbs(image_only, :);

            iobbs(:, [1 3]) = min(iobbs(:, [1 3]), imax_w);
            iobbs(:, [2 4]) = min(iobbs(:, [2 4]), imax_h);

            iobbs(:, [3 4]) = iobbs(:, [3 4]) - iobbs(:, [1 2]) + 1;
            ioscores = scores(image_only, :);

            [iobbs, ioscores, idx] = reduce_matches(params, iobbs, ioscores);
            info('Reduced %d patches to %d', length(image_only), size(iobbs, 1));
            scores2 = [scores2; ioscores];
            bbs2 = [bbs2; iobbs];
            images2 = [images2, ones([1 size(iobbs, 1)]) * image];
            resnum = [resnum, image_only(idx)];
            patches = [patches, 1:length(ioscores)];
            numWindows = [numWindows, ones([1 size(iobbs, 1)]) * size(iobbs, 1)];
        end
        [scores2, idx] = sort(scores2, 'descend');

        % first 100
        scores2 = scores2(1:min([100, length(scores2)]));
        idx = idx(1:min([100, length(idx)]));

        bbs2 = bbs2(idx, :);
        images2 = images2(idx);
        resnum = resnum(idx);
        patches = patches(idx);
        numWindows = numWindows(idx);

        for i=1:length(resnum)
            si = resnum(i);
            pi = patches(i);
            image = images2(i);
            bbs = bbs2(i, :);
            bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;

            result(si).query_curid = svm_models.curid;
            result(si).curid = database(image).curid;
            result(si).img = image;
            result(si).patch = pi;
            result(si).score = scores2(i);
            result(si).bbox = bbs;
            result(si).num_windows = numWindows(i);
        end
        toremove = cellfun(@isempty, {result.curid});
        result(toremove) = [];
    end
end

function complete(skip_comb, skip_scale, force)
    % Does overall tests with the demo function
    clusters = {512, 1000};
    clusters = {512};
    parts = {1, 4};
    parts = {1};
    window_filtered = {true, false};
    scale_ranges = {3, 1};
    scale_ranges = {3};
    images = {'2008_004363', '2009_004882', '2010_005116', '2009_000634', '2010_003701'};
    %images = {'2008_004363', '2009_004882', '2010_003701'};
    %images = {'2009_000634', '2010_003701'};
    window_image_ratio = {1, 0.75};
    query_from_integral = {true, false};
    %just for speed up, maybe not best performance
    %query_from_integral = {false};
    nonmax_min = {true, false};
    dbtypes = {'database2', 'database', 'val'};
    dbtypes = {'val'};
%    dbtypes = {'database2'};

    combinations = cartproduct(images, clusters, parts, window_filtered, scale_ranges, window_image_ratio, query_from_integral, nonmax_min, dbtypes);
    num_comb = length(combinations(:));
    for ic=1:num_comb
        if ic < skip_comb
            continue;
        end
        skip_comb = 0;
        % parameters
        fileid = combinations{ic}{1};
        clusters = combinations{ic}{2};
        parts = combinations{ic}{3};
        window_filtered = combinations{ic}{4};
        scale_range = combinations{ic}{5};
        window_image_ratio = combinations{ic}{6};
        query_from_integral = combinations{ic}{7};
        nonmax_min = combinations{ic}{8};
        dbtype = combinations{ic}{9};

        % filename specification
        if window_filtered
            filtered = 'filtered';
        else
            filtered = 'unfiltered';
        end
        if query_from_integral
            query_source = 'integral';
        else
            query_source = 'raw';
        end
        if nonmax_min
            nonmax = 'min';
        else
            nonmax = 'union';
        end

        if strcmp(fileid, images{1})
            rounds = 10;
        elseif strcmp(fileid, images{2})
            rounds = 5;
        else
            rounds = 1;
        end

        caching = false;
        if strcmp(dbtype, 'database')
            stream_max = 100;
            %filename = sprintf('results/timings/total-%d-%d-%s-%d-%.2f-%s-%s-%s.mat',...
            %                   clusters, parts, filtered, scale_range, window_image_ratio, query_source, fileid, nonmax);
        else
            rounds = 1;
            caching = true;
            if strcmp(dbtype, 'val')
                stream_max = 2500;
            else
                stream_max = 1000;
            end
        end
        filename = sprintf('results/timings/%s/total-%d-%d-%s-%d-%.2f-%s-%s-%s.mat',...
                           dbtype, clusters, parts, filtered, scale_range, window_image_ratio, query_source, fileid, nonmax);

        %window_scalings = {1, 2, 3, 4, 5, 0};
        % skip legacy window generation (value of 0)
        window_scalings = {1, 2, 3, 4, 5, 0.5};
        results = cell([1 length(window_scalings)]);
        num_windows = zeros([1 length(window_scalings)]);
        elapsed_time = zeros([1 length(window_scalings)]);

        % load time from file if available
        if exist(filename, 'file') && skip_scale == 0 && ~force
            tmp = load_ex(filename);
            if isfield(tmp, 'elapsed_time')
                elapsed_time = tmp.elapsed_time;
                rounds = 1;
            end
            if length(tmp.num_windows(:)) == length(num_windows) && length(tmp.results(:)) == length(results)
                num_windows = tmp.num_windows;
                results = tmp.results;
            end
        end
        info('File: %s', filename);

        window_scaling_len = length(window_scalings);
        for wi=1:window_scaling_len
            if wi < skip_scale
                continue
            end
            if num_windows(wi) > 0 && ~isempty(results{wi})
                fprintf('#Windows: %d\n', num_windows(wi));
                continue
            end
            skip_scale = 0;
            window_scaling = window_scalings{wi};
            start_time = tic;
            for i=1:rounds
                info('Combination: %2d/%02d', ic, num_comb);
                info('Scalings: %d/%d', wi, length(window_scalings));
                info('Round: %d/%d', i, rounds);
                info('Done: %d/%d', ((ic-1)*window_scaling_len*rounds+(wi-1)*rounds+i), (num_comb*window_scaling_len*rounds));
                % Start the test
                [r, nw] = demo(false,...
                               'use_kdtree', true,...
                               'window_prefilter', window_filtered,...
                               'clusters', clusters,...
                               'naiive_integral_backend', false,...
                               'use_threading', false,...
                               'memory_cache', caching,...
                               'parts', parts,...
                               'query_from_integral', query_from_integral,...
                               'log_file', '/dev/null',...
                               'log_level', 'info',...
                               'use_calibration', false,...
                               'no_create', false,...
                               'use_libsvm_classification', false,...
                               'codebook_scales_count', scale_range,...
                               'default_query_file', fileid,...
                               'max_window_image_ratio', window_image_ratio,...
                               'nonmax_type_min', nonmax_min,...
                               'db_stream_name', dbtype,...
                               'stream_max', stream_max,...
                               'window_generation_relative_move', window_scaling);
                results{wi} = r;
                num_windows(wi) = nw;
            end

            if elapsed_time(wi) == 0
                elapsed_time(wi) = toc(start_time)/rounds;
            end
            save_ex(filename, '-v6', 'results', 'num_windows', 'elapsed_time');
        end
    end
end

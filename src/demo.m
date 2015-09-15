function demo(train, varargin)
%DEMO Demo implementation
%
%   Syntax: demo(stream_size, scale_factor, codebook_type, train, scale_count)
%
%   Input:
%       stream_size - Optional size of pascal objects to process. Default: 100
%       scale_factor - Optional integral image scale factor. Default: 0.75, Valid: 0-1
%       codebook_type - Optional datatype of codebooks. Default: 'double', Valid: 'double', 'single'
%       train - Optional boolean to indicate the creation of a image database. Default: false
%       scale_count - Optional number of different scales of integral images to use. Default: 3


    close all;
    dbstop if error;
%    dbstop in demo at 252;
    addpath(genpath('vendors'));
    addpath(genpath('src/internal'));

    params = get_default_configuration;
    keywords = parse_keywords(varargin, fieldnames(params));
    params = merge_structs(params, keywords);
    if exist('scale_factor', 'var')
         params.integrals_scale_factor = scale_factor; % save only 3 of 4 entries
    end
    if exist('stream_size', 'var')
        params.stream_max = stream_size;
    end
    if exist('codebook_type', 'var')
        params.codebook_type = codebook_type;
    end
    if exist('scale_count', 'var')
        params.codebook_scales_count = scale_count;
    end
    % print params
    params

    params = profile_start(params);

    if exist('train', 'var') && train
        cluster_model = generateCluster(params);
        getImageDB(params, cluster_model);

        params.feature_type = 'full-masked';
        params.stream_name = 'query';

        fprintf('[*] Collecting negative features...\n');
        neg_features = prepare_features(params);

        fprintf('[*]Getting negative codebooks...\n');
        get_codebooks(params, neg_features, cluster_model);
        profile_stop(params);
        fprintf('[+] DONE\n');
    else
        cluster_model = generateCluster(params);
        searchInteractive(params, cluster_model);
    end
end

function cluster_model = generateCluster(params)
%GENERATECLUSTER Generate a cluster model
%
%   Syntax:     cluster_model = generateCluster(params)
%
%   Input:
%       params - Configuration parameters
%
%   Output:
%       cluster_model - The model

    profile_log(params);
    params.feature_type = 'full';
    params.stream_name = 'database';
    params.class = '';

    cluster_model = get_cluster(params, []);
    if ~isstruct(cluster_model)
        train_features = prepare_features(params);
        cluster_model = get_cluster(params, train_features);
    end
end

function database = getImageDB(params, cluster_model)
%GETIMAGEDB Generate or load the image database
%
%   Syntax:     database = getImageDB(params, cluster_model)
%
%   Input:
%       params - Configuration parameters
%       cluster_model - The model for codebook generation
%
%   Output:
%       database - The database of integral images

    params.feature_type = 'full';
    params.stream_name = 'database';
    params.class = '';

    all_features = prepare_features(params);

    database = get_codebook_integrals(params, all_features, cluster_model);
end

function svm_models = getSVM(params, cluster_model)
%GETSVM Train or load a exemplar SVM
%
%   Syntax:     svm_models = getSVM(params, cluster_model)
%
%   Input:
%       parms - Configuration parameters
%       cluster_model - The model to generate codebooks
%
%   Output:
%       svm_models - SVM model struct

    params.stream_name = 'query';

    params.feature_type = 'bboxed';
    query_features = prepare_features(params);

    query_codebooks = get_codebooks(params, query_features, cluster_model);
    clear query_features;

    params.feature_type = 'full-masked';
    neg_features = prepare_features(params);

    neg_codebooks = get_codebooks(params, neg_features, cluster_model);
    clear neg_features;

    svm_models = get_svms(params, query_codebooks, neg_codebooks);
end

function results = searchInteractive(params, cluster_model)
%SEARCHINTERACTIVE Do a complete interactive database search
%   Asks the user for a image in the dataset image path.
%   Allows to mark a ROI to search for
%   Stores results in the results/queries subdirectories
%
%   Syntax:     searchInteractive(params, cluster_model)
%
%   Input:
%       params - Configuration parameters
%       cluster_model - The model to generate codebooks

    % start loading of
    profile_log(params);
    startpath = strrep(params.dataset.imgpath, '%s', params.default_query_file);

    if usejava('desktop')
        neg_codebooks_job = parfeval(@get_neg_codebooks, 1, params);
        f = figure('Position', [100, 100, 1024+40, 768 + 100], 'Resize', 'off');
        axis image;
        ax = axes('Units', 'pixels', 'Position', [20, 80, 1024, 768]);
    end

    selected_img = select_img();

    if isfield(params, 'default_bounding_box') && ~isempty(params.default_bounding_box)
        pos = params.default_bounding_box;
    else
        pos = [];
    end

    if usejava('desktop')
        img = uicontrol('Style', 'pushbutton',...
            'String', 'Select Image',...
            'Position', [20 20 100 20],...
            'UserData', selected_img,...
            'Callback', @select_img);

        btn = uicontrol('Style', 'pushbutton',...
            'String', 'Search',...
            'Position', [130 20 60 20],...
            'Enable', 'off',...
            'Callback', @process);

        label = uicontrol('Style','text',...d
                    'String','Select exemplar',...
                    'HorizontalAlignment','left',...
                    'Position',[20 40 1000 30]);


        if ~isempty(pos)
            h = imrect(ax, pos);
        else
            h = imrect(ax);
        end
        addNewPositionCallback(h, @(pos) set(label, 'String', sprintf('Selected: %s %4.0f,%4.0f,%4.0f,%4.0f', img.UserData.filename, pos(1), pos(2), pos(3), pos(4))));
        fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
        setPositionConstraintFcn(h,fcn);

        pos = round(getPosition(h));
        btn.Enable = 'on';
        selected_img = img.UserData;
    end

    setStatus(sprintf('Selected: %s %d,%d,%d,%d', selected_img.filename, pos(1), pos(2), pos(3), pos(4)));

    % run directly if in cli mode
    if ~usejava('desktop')
        results = process([], []);
    else
        uiwait;
        results = btn.UserData;
    end

    function setStatus(txt)
        if usejava('desktop')
            selected_img = img.UserData;
        end

        sec = toc(selected_img.total_time);
        txt = sprintf('%s (%f sec)', txt, sec);
        fprintf('[*] %s\n', txt);

        if usejava('desktop')
            set(label, 'String', txt);
            drawnow();
        end
    end

    function selected_img = select_img(source, cbdata)
        if ~usejava('desktop')
            [~, fname, ext] = fileparts(startpath);
            selected_img.filename = [fname ext];
            selected_img.I = imread(startpath);
            selected_img.total_time = tic;
            return;
        end

        if exist('source', 'var')
            selected_img = source.UserData;
        end

        [selected_img.filename, pathname] = uigetfile('*.jpg;*.png;*.gif;*.tif;*.bmp','Select the image which contains the exemplar', startpath);
        query_filename = [pathname filesep selected_img.filename];
        selected_img.I = imread(query_filename);
        selected_img.total_time = tic;
        imshow(selected_img.I, 'Parent', ax);
        set(gca,'xtick',[],'ytick',[]);

        if exist('source', 'var')
            source.UserData = selected_img;
        end

        shg;
    end

    function neg_codebooks = get_neg_codebooks(params)
        params.stream_name = 'query';
        params.feature_type = 'full-masked';
        neg_codebooks = get_codebooks(params, [], cluster_model);
        if ~isstruct(neg_codebooks)
            %setStatus('Collecting negative features...');
            neg_features = prepare_features(params);
            neg_codebooks = get_codebooks(params, neg_features, cluster_model);
            clear neg_features;
        end
        
        %setStatus('Concating codebooks...');
        neg_codebooks = horzcat(neg_codebooks.I);
    end

    function results = process(source, cbdata)
        profile_log(params);
        if usejava('desktop')
            selected_img = img.UserData;
        end

        selected_img.total_time = tic;

        if usejava('desktop')
            img.UserData = selected_img;
        end

        old_params = params;
        params.stream_name = 'query';

        [~, curid, ~] = fileparts(selected_img.filename);

        target_dir = get_target_dir(params, curid);
        if exist(target_dir, 'dir')
            rmdir(target_dir, 's');
        end
        fprintf('++ Using target dir %s\n', target_dir);
        mkdir(target_dir);

        if usejava('desktop')
            pos = round(getPosition(h));
        end

        roi_size = pos([3 4]);
        pos([3 4]) = pos([3 4]) + pos([1 2]) - 1;

        croppedI = selected_img.I(pos(2):pos(4), pos(1):pos(3), :);
        imwrite(croppedI, [target_dir filesep 'query.jpg']);

        if usejava('desktop')
            %database_job = parfeval(@load_database, 1, params, cluster_model, roi_size);
        end
        setStatus('Getting negative codebooks...');
        if exist('neg_codebooks_job', 'var')
            [~, neg_codebooks] = fetchNext(neg_codebooks_job);
        else
            neg_codebooks = get_neg_codebooks(params);
        end

        setStatus('Get features from selected part...');
        query_file.I = selected_img.I;
        query_file.bbox = pos;
        query_file.cls = 'unknown';
        query_file.objectid = 1;
        query_file.curid = curid;

        params.stream_max = 1;
        if params.query_from_integral
            params.feature_type = 'full';
        else
            params.feature_type = 'bboxed';
            params.dataset.localdir = [];
        end

        setStatus('Loading neg model for whitening...');
        profile_log(params);
        if evalin('base', 'exist(''NEG_MODEL'', ''var'');')
            fprintf('++ Using preloaded negative model\n');
            params.neg_model = evalin('base', 'NEG_MODEL;');
        else
            params.neg_model = get_full_neg_model();
            assignin('base', 'NEG_MODEL', params.neg_model);
        end
        profile_log(params);
        setStatus('Filtering query features...');

        if params.query_from_integral
            query_integrals = get_codebook_integrals(params, [], cluster_model, roi_size);
            if ~isstruct(query_integrals)
                query_features = prepare_features(params, {query_file});
                query_integrals = get_codebook_integrals(params, query_features, cluster_model, roi_size);
                clear query_features;
            end
            [ query_codebooks.size, query_codebooks.I, ~ ] = calc_codebooks(params, query_integrals, query_file.bbox, params.parts );
            query_codebooks.I = query_codebooks.I';
            query_codebooks.curid = query_file.curid;
        else            
            query_features = prepare_features(params, {query_file});
            query_codebooks = get_codebooks(params, query_features, cluster_model);
            clear query_features;
        end

        setStatus('Train SVM...');
        params.dataset.localdir = old_params.dataset.localdir;
        svm_models = get_svms(params, query_codebooks, neg_codebooks);
        params.dataset.localdir = [];
        clear neg_codebooks;

        if params.use_calibration
            setStatus('Calibrate...');
            fit_params = calibrate_fit(params, svm_models, {query_file}, cluster_model);
        else
            fit_params = [];
        end

        setStatus('Loading database...');
        if exist('database_job', 'var')
            %[~, database] = fetchNext(database_job);
        else
            database = load_database(old_params, cluster_model, roi_size);
        end
        setStatus('Searching in database...');
        results = searchDatabase(old_params, database, svm_models, fit_params, pos);
        setStatus('DONE!');
        profile_stop(params);
        
        if usejava('desktop')
            btn.UserData = results;
            uiresume;
        end
    end

    function database = load_database(params, cluster_model, roi_size)
        params.feature_type = 'full';
        params.stream_name = 'database';
        params.class = '';
        database = get_codebook_integrals(params, [], cluster_model, roi_size);
        if ~isstruct(database)
            all_features = prepare_features(params);
            database = get_codebook_integrals(params, all_features, cluster_model, roi_size);
        end
    end
end

function results = searchDatabase(params, database, svm_models, fit_params, pos)
%SEARCHDATABASE Search the image database with the given SVM models
%   Stores results in the results/queries subdirectories
%
%   Syntax:     results = searchDatabase(params, database, svm_models, fit_params, roi)
%
%   Input:
%       params - Configuration parameters
%       database - The image database as struct array of integral codebook images
%       svm_models - Struct array of svm models
%       fit_params - Gaussian curve 2D Vectors to adjust the SVM scores [$\mu$, $\sigma$]
%       roi - The region of interest [x_{min}, y_{min}, x_{max}, y_{max}]
%
%   Output:
%       results - Cell array of results. Fields: curid, img, patch, score
    profile_log(params);
    sizes = cellfun(@(I) size(I), {database.I}, 'UniformOutput', false);
    sizes = cell2mat(vertcat(sizes(:)));
    scale_factors = {database.scale_factor};
    scale_factors = cell2mat(vertcat(scale_factors(:)));
    max_w = max(sizes(:, 3) ./ scale_factors);
    max_h = max(sizes(:, 4) ./ scale_factors);

    roi_w = pos(3) - pos(1) + 1;
    roi_h = pos(4) - pos(2) + 1;
    windows = calc_windows(max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
    [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, params.parts );
    % save space
    database = rmfield(database, 'I');
    % required for libsvm
    codebooks = double(codebooks);
    results = cell([1 length(svm_models)]);
    for mi=1:length(svm_models)
        model = svm_models(mi);

        target_dir = get_target_dir(params, model.curid);

        fprintf('Classifying patches...');
        tmp = tic;
        scores = model.classify(params, model, codebooks);
        fprintf('DONE in %f sec\n', toc(tmp));
        if params.use_calibration
            scores = adjust_scores(params, fit_params, scores);

            matches = scores > -0.25;
        else
            matches = true([1 length(scores)]);
        end
        fprintf('Found matches for %s: %d\n', model.curid, sum(matches));
        scores = scores(matches);
        mimg = images(matches);
        umimg = unique(mimg);
        mbbs = bboxes(matches, :);

        [scores, idx] = sort(scores, 'descend');
        mimg = mimg(idx);
        mbbs = round(mbbs(idx, :));
        result = struct;
        if ~isempty(scores)
            result(length(scores)).query_curid = model.curid;
        end

        for ii=1:length(umimg)
            image = umimg(ii);

            image_only = find(mimg == image);
            iobbs = mbbs(image_only, :);
            iobbs(:, [3 4]) = iobbs(:, [3 4]) - iobbs(:, [1 2]) + 1;
            ioscores = scores(image_only, :);

            [iobbs, ioscores, idx] = reduce_matches(params, iobbs, ioscores);
            fprintf('Reduced %d patches to %d\n', length(image_only), size(iobbs, 1));
            for pi=1:length(ioscores)
                si = image_only(idx(pi));
                I = get_image(params, database(image).curid);
                bbs = iobbs(pi, :);
                bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;
                I = I(bbs(2):bbs(4), bbs(1):bbs(3), :);

                filename = sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, ioscores(pi), image, pi);
                imwrite(I, filename);

                result(si).query_curid = model.curid;
                result(si).curid = database(image).curid;
                result(si).img = image;
                result(si).patch = pi;
                result(si).score = ioscores(pi);
                result(si).bbox = bbs;
                result(si).filename = filename;
            end
        end

%         patchnrs = zeros([max(mimg) 1]);
%         result = struct;
%         if length(scores) > 0
%             result(length(scores)).curid = model.curid;
%         end
%         for si=1:length(scores)
%             I = get_image(params, database(mimg(si)).curid);
%             bbs = mbbs(si, :);
%             I = I(bbs(2):bbs(4), bbs(1):bbs(3), :);
%             patchnrs(mimg(si)) = patchnrs(mimg(si)) + 1;
%             imwrite(I, sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, scores(si), mimg(si), patchnrs(mimg(si))));
%
%             result(si).curid = model.curid;
%             result(si).img = mimg(si);
%             result(si).patch = patchnrs(mimg(si));
%             result(si).score = scores(si);
%         end
        results{mi} = result;
    end
end

function fit_params = calibrate_fit(params, svm_models, query_file, cluster_model)
%CALIBRATE_FIT Estimates the gaussian parameters for the given svm models
%
%   Syntax:     fit_params = calibrate_fit(params, svm_models, query_file, cluster_model)
%
%   Input:
%       params - Configuration parameters
%       svm_models - The SVM models
%       query_file - A pascal stream containing the file used to train the SVM
%       cluster_model - The model to generate the codebooks
%
%   Output:
%       fit_params - Nx2 matrix of gaussian parameters. N: number of SVM models, Gaussian Parameters: [$\mu$, $\sigma$]

    profile_log(params);
    params.feature_type = 'full';
    features = get_features_from_stream(params, query_file);
    features = whiten_features(params, features);
    features = filter_features(params, features);
    codebooks = get_codebooks(params, features, cluster_model);
    codebooks = double(horzcat(codebooks.I));
    clear features;


    fit_params = zeros([length(svm_models) 2]);
    for mi=1:length(svm_models)
        svm_model = svm_models(mi);

        scores = svm_model.classify(params, svm_model, codebooks);
        fit_params(mi, :) = estimate_fit_params(params, scores);
    end
end

function rhos = calibrate_rho(params, svm_models, query_file, cluster_model, ground_truths)
%CALIBRATE_RHO Tries to readjust the rho of the given SVM models to obtain better scores
%
%   Syntax:     rhos = calibrate_rho(params, svm_models, query_file, cluster_model, ground_truths)
%
%   Input:
%       params - Configuration parameters
%       svm_models - The SVM models
%       query_file - A pascal stream containing the file used to train the SVM
%       cluster_model - The model to generate the codebooks
%       ground_truths - Nx4 Matrix of bounding boxes inside the query image (e.g. the ROI)
%
%   Output:
%       rhos - Mx1 vector of new rhos. M: number of SVM models

    profile_log(params);
    params.feature_type = 'full';
    features = get_features_from_stream(params, query_file);
    features = whiten_features(params, features);
    features = filter_features(params, features);
    codebooks = get_codebooks(params, features, cluster_model);
    codebooks = horzcat(codebooks.I);
    clear features;

    rhos = zeros([length(svm_models) 1]);
    for mi=1:length(svm_models)
        svm_model = svm_models(mi);
        scores = svm_model.classify(params, svm_model, codebooks);
        windows = calc_windows(features.I_size(2), features.I_size(1));
        % TL
        matchingTL = windows(:, 1) <= ground_truths(1) & ground_truths(1) <= windows(:, 3);
        matchingTL = windows(:, 2) <= ground_truths(2) & ground_truths(2) <= windows(:, 4) & matchingTL;
        % BL
        matchingBL = windows(:, 1) <= ground_truths(1) & ground_truths(1) <= windows(:, 3);
        matchingBL = windows(:, 2) <= ground_truths(4) & ground_truths(4) <= windows(:, 4) & matchingBL;
        % TR
        matchingTR = windows(:, 1) <= ground_truths(3) & ground_truths(3) <= windows(:, 3);
        matchingTR = windows(:, 2) <= ground_truths(2) & ground_truths(2) <= windows(:, 4) & matchingTR;
        % BR
        matchingBR = windows(:, 1) <= ground_truths(3) & ground_truths(3) <= windows(:, 3);
        matchingBR = windows(:, 2) <= ground_truths(4) & ground_truths(4) <= windows(:, 4) & matchingBR;
        % enclosing
        matchingEC = windows(:, 1) >= ground_truths(1) & ground_truths(3) >= windows(:, 3);
        matchingEC = windows(:, 2) >= ground_truths(2) & ground_truths(4) >= windows(:, 4) & matchingEC;

        matching = matchingTL | matchingBL | matchingTR | matchingBR | matchingEC;

        [scores, idx] = sort(scores, 'descend');
        matching = matching(idx);
        zero = find(~matching, 1);
        fprintf('First zero: %d (%f)\n', zero, scores(zero));
        nonzero = find(matching, 1, 'last');
        fprintf('Last non-zero: %d (%f)\n', nonzero, scores(nonzero));
        remaining_scores = scores(matching);
        fprintf('Min: %f Mean: %f Max: %f\n', min(remaining_scores), mean(remaining_scores), max(remaining_scores));
    end
end

function [bbox, scores, idx] = reduce_matches(params, bbox, scores)
%REDUCE_MATCHES Reduces the amount of detected matches with a non-max suppression
%
%   Syntax:     [bbox, scores, idx] = reduce_matches(params, bbox, scores)
%
%   Input:
%       params - Configuration parameters
%       bbox - Nx4 matrix of bounding boxes [x, y, w, h]
%       scores - N dimensional vector of scores
%
%   Output:
%       bbox - New bounding boxes
%       scores - New scores
%       idx - Mapping between input and output (index vector)

    profile_log(params);
    if params.nonmax_type_min
        [bbox, scores, idx] = selectStrongestBbox(bbox, scores, 'RatioType', 'Min');
    else
        [bbox, scores, idx] = selectStrongestBbox(bbox, scores, 'RatioType', 'Union');
    end
end

function features = prepare_features(params, query_stream_set)

    if ~exist('query_stream_set', 'var')
        stream_params.stream_set_name = params.stream_name;
        stream_params.stream_max_ex = params.stream_max;
        stream_params.must_have_seg = 0;
        stream_params.must_have_seg_string = '';
        stream_params.model_type = 'exemplar';
        stream_params.cls = params.class;

        query_stream_set = esvm_get_pascal_stream_custom(stream_params, ...
                                              params.dataset);
    end

    features = filter_features(params, []);
    if isempty(features)
        features = whiten_features(params, []);
        if isempty(features)
            features = get_features_from_stream(params, query_stream_set);
            fprintf('[*] Whitening features...\n');
            features = whiten_features(params, features);
        end
        fprintf('[*] Filtering features...\n');
        features = filter_features(params, features);
    end
end

function target_dir = get_target_dir(params, curid)
    if params.nonmax_type_min
        nonmax_type = 'min';
    else
        nonmax_type = 'union';
    end

    if params.use_calibration
        calib_type = 'calibrated';
    else
        calib_type = 'uncalibrated';
    end
    
    if params.query_from_integral
        query_src = 'integral';
    else
        query_src = 'raw';
    end

    target_dir = [params.dataset.localdir filesep 'queries' filesep 'scaled'...
                filesep num2str(params.clusters) '-Cluster'...
                filesep num2str(params.stream_max) '-Imgs' filesep...
                num2str(params.integrals_scale_factor) '-IntScale' filesep...
                params.codebook_type filesep...
                num2str(params.codebook_scales_count) '-NumScales' filesep...
                'nonmax-' nonmax_type filesep calib_type filesep...
                num2str(params.features_per_roi) '-featPerRoi' filesep...
                'querysrc-' query_src filesep curid];
end

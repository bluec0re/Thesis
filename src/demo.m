function demo(train, varargin)
%DEMO Demo implementation
%
%   Syntax: demo(train, ...)
%
%   Input:
%       train - boolean to indicate the creation of a image database. Default: false
%       Name-Value pairs to override the default configuration


    close all;
    dbstop if error;
%    dbstop in demo at 252;
    addpath(genpath('vendors'));
    addpath(genpath('src/api'));
    addpath(genpath('src/internal'));

    params = get_default_configuration;
    params.log_file = 'demo.log';
    params.log_level = 'debug';
    keywords = parse_keywords(varargin, fieldnames(params));
    params = merge_structs(params, keywords);
    params.default_bounding_box = params.get_bounding_box(params);

    log_file(params.log_file);
    set_log_level(params.log_level);
    % print params
    debg('Params:\n%s', struct2str(params));

    %params = profile_start(params);

    if exist('train', 'var') && train
        cluster_model = generateCluster(params);
        getImageDB(params, cluster_model);

        params.feature_type = 'full-masked';
        params.stream_name = 'query';

        info('Collecting negative features...');
        neg_features = prepare_features(params);

        info('Getting negative codebooks...');
        get_codebooks(params, neg_features, cluster_model);
        profile_stop(params);
        succ('DONE');
    else
        cluster_model = generateCluster(params);
        searchInteractive(params, cluster_model);
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
    if ~params.precalced_windows
        if nargout > 0
            database = get_codebook_integrals(params, all_features, cluster_model);
        else
            fprintf('Generate only\n');
            get_codebook_integrals(params, all_features, cluster_model);
        end
    else
        if nargout > 0
            database = get_codebook_from_windows(params, all_features, cluster_model);
        else
            fprintf('Generate only\n');
            get_codebook_from_windows(params, all_features, cluster_model);
        end
    end
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
    start_time = tic;

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
        info('%s', txt);

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
        debg('++ Using target dir %s', target_dir);
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
        if params.memory_cache && evalin('base', 'exist(''NEG_MODEL'', ''var'');')
            debg('++ Using preloaded negative model');
            params.cache.neg_model = evalin('base', 'NEG_MODEL;');
        elseif ~params.query_from_integral
            params.cache.neg_model = get_full_neg_model();
            assignin('base', 'NEG_MODEL', params.cache.neg_model);
        end
        profile_log(params);
        setStatus('Filtering query features...');

        params.dataset.localdir = old_params.dataset.localdir;
        query_codebooks.size = roi_size;
        query_codebooks.curid = curid;
        svm_models = get_svms(params, query_codebooks, []);
        if ~isstruct(svm_models)
            if ~params.query_from_integral
                params.dataset.localdir = [];
            end
            query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size );
            debg('Got %d codebooks', length(query_codebooks));

            setStatus('Train SVM...');
            params.dataset.localdir = [];%old_params.dataset.localdir;
            svm_models = get_svms(params, query_codebooks, neg_codebooks);
        end
        params.dataset.localdir = [];
        clear neg_codebooks;


        if params.use_calibration
            setStatus('Calibrate...');
            fit_params = calibrate_fit(params, svm_models, query_file, cluster_model);
        else
            fit_params = [];
        end

        if isfield(params, 'cache')
            params = rmfield(params, 'cache');
        end
        setStatus('Loading database...');
        if ~params.precalced_windows
            if exist('database_job', 'var')
                %[~, database] = fetchNext(database_job);
            else
                database = load_database(old_params, cluster_model, roi_size);
            end
            setStatus('Searching in database...');
            results = searchDatabase(old_params, database, svm_models, fit_params, pos);
        else
            database = load_window_database(old_params, cluster_model, roi_size);
            setStatus('Searching in database...');
            results = searchWindowDatabase(old_params, database, svm_models, fit_params, pos);
        end

        % remove unnecessary fields
        cleanparams = clean_struct(params, {'cache', 'profile'});

        elapsed_time = toc(start_time);
        save_ex([target_dir filesep 'results.mat'], 'results', 'cleanparams', 'elapsed_time');
        setStatus('DONE!');
        profile_stop(params);

        if usejava('desktop')
            btn.UserData = results;
            uiresume;
        end
    end

    function database = load_window_database(params, cluster_model, roi_size)
        params.feature_type = 'full';
        params.stream_name = 'database';
        params.class = '';
        database = get_codebook_from_windows(params, [], cluster_model, roi_size);
        if ~isstruct(database)
            all_features = prepare_features(params);
            database = get_codebook_from_windows(params, all_features, cluster_model, roi_size);
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
    sizes = {database.I_size};
    sizes = cell2mat(vertcat(sizes(:)));
    scale_factors = {database.scale_factor};
    scale_factors = cell2mat(vertcat(scale_factors(:)));
    max_w = max(sizes(:, 3) ./ scale_factors);
    max_h = max(sizes(:, 4) ./ scale_factors);

    roi_w = pos(3) - pos(1) + 1;
    roi_h = pos(4) - pos(2) + 1;
    windows = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
    [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, params.parts, svm_models);
    % save space
    % database = rmfield(database, 'I');
    % if isfield(database, 'tree')
    %     database = rmfield(database, 'tree');
    % end

    % expand bounding boxes by 1/2 of patch average
    if params.expand_bboxes
        patch_avg = ceil((max(vertcat(database.max_size)) + min(vertcat(database.min_size))) / 2 / 2);
        patch_avg = repmat(patch_avg, [size(bboxes, 1) 2]);
        patch_avg = patch_avg .* repmat([-1 -1 1 1], [size(bboxes, 1) 1]);
        bboxes = bboxes + patch_avg;
        bboxes(:, [1 3]) = max(1, min(bboxes(:, [1 3]), max_w));
        bboxes(:, [2 4]) = max(1, min(bboxes(:, [2 4]), max_h));
    end

    % required for libsvm
    codebooks = double(codebooks);
    results = cell([1 length(svm_models)]);
    for mi=1:length(svm_models)
        model = svm_models(mi);

        target_dir = get_target_dir(params, model.curid);
        info('Classifying patches...');
        tmp = tic;
        scores = model.classify(params, model, codebooks);
        succ('DONE in %f sec', toc(tmp));
        if params.use_calibration
            scores = adjust_scores(params, fit_params, scores);

            matches = scores > -0.25;
        else
            matches = true([1 length(scores)]);
        end
        info('Found matches for %s: %d', model.curid, sum(matches));
        scores = scores(matches);
        mimg = images(matches);
        umimg = unique(mimg);
        mbbs = bboxes(matches, :);

        [scores, idx] = sort(scores, 'descend');
        mimg = mimg(idx);
        mbbs = round(mbbs(idx, :));
        result = struct;
        if ~isempty(scores)
            result = alloc_struct_array(length(scores), 'curid', 'query_curid', 'img', 'patch', 'score', 'bbox', 'filename');
            result(length(scores)).query_curid = model.curid;
        end

        if params.use_calibration
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
                for pi=1:length(ioscores)
                    si = image_only(idx(pi));
                    bbs = iobbs(pi, :);
                    bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;
                    %I2 = I(bbs(2):bbs(4), bbs(1):bbs(3), :);
                    blend_mask = true([size(I, 1) size(I, 2)]);
                    blend_mask(bbs(2):bbs(4), bbs(1):bbs(3)) = false;
                    overlay = zeros([size(I, 1) size(I, 2)], 'uint8');
                    I2 = alpha_blend(I, overlay, 0.4, blend_mask);
                    %I2 = I(bbs(1):bbs(3), bbs(2):bbs(4), :);

                    filename = sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, ioscores(pi), image, pi);
                    imwrite(I2, filename);

                    result(si).query_curid = model.curid;
                    result(si).curid = database(image).curid;
                    result(si).img = image;
                    result(si).patch = pi;
                    result(si).score = ioscores(pi);
                    result(si).bbox = bbs;
                    result(si).filename = filename;
                end
            end
        else
            scores2 = [];
            bbs2 = [];
            images2 = [];
            resnum = [];
            patches = [];
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
            end
            [scores2, idx] = sort(scores2, 'descend');

            % first 100
            scores2 = scores2(1:min([100, length(scores2)]));
            idx = idx(1:min([100, length(idx)]));

            bbs2 = bbs2(idx, :);
            images2 = images2(idx);
            resnum = resnum(idx);
            patches = patches(idx);

            for i=1:length(resnum)
                si = resnum(i);
                pi = patches(i);
                image = images2(i);
                I = get_image(params, database(image).curid);
                bbs = bbs2(i, :);
                bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;
                %I2 = I(bbs(2):bbs(4), bbs(1):bbs(3), :);
                blend_mask = true([size(I, 1) size(I, 2)]);
                blend_mask(bbs(2):bbs(4), bbs(1):bbs(3)) = false;
                overlay = zeros([size(I, 1) size(I, 2)], 'uint8');
                I2 = alpha_blend(I, overlay, 0.4, blend_mask);
                %I2 = I(bbs(1):bbs(3), bbs(2):bbs(4), :);

                filename = sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, scores2(i), image, pi);
                imwrite(I2, filename);

                result(si).query_curid = model.curid;
                result(si).curid = database(image).curid;
                result(si).img = image;
                result(si).patch = pi;
                result(si).score = scores2(i);
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
        % remove all empty results
        if ~isempty(result) && isfield(result, 'curid')
            result = result(~cellfun(@isempty, {result.curid}));
            results{mi} = result;
        else
            err('No results for %s', model.curid);
        end
    end
end

function results = searchWindowDatabase(params, database, svm_models, fit_params, pos)
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

    bboxes = cat(1, database.bboxes);
    codebooks = cat(1, database.codebooks);
    images = cellfun(@(i, x) i*ones([size(x, 1) 1]), num2cell(1:50), {database.codebooks}, 'UniformOutput', false);
    images = cat(1, images{:});

    % expand bounding boxes by 1/2 of patch average
    if params.expand_bboxes && false
        patch_avg = ceil((max(vertcat(database.max_size)) + min(vertcat(database.min_size))) / 2 / 2);
        patch_avg = repmat(patch_avg, [size(bboxes, 1) 2]);
        patch_avg = patch_avg .* repmat([-1 -1 1 1], [size(bboxes, 1) 1]);
        bboxes = bboxes + patch_avg;
        %TODO max_w & max_h missing
        bboxes(:, [1 3]) = max(1, min(bboxes(:, [1 3]), max_w));
        bboxes(:, [2 4]) = max(1, min(bboxes(:, [2 4]), max_h));
    end

    % required for libsvm
    codebooks = double(codebooks);
    results = cell([1 length(svm_models)]);
    for mi=1:length(svm_models)
        model = svm_models(mi);

        target_dir = get_target_dir(params, model.curid);
        info('Classifying patches...');
        tmp = tic;
        scores = model.classify(params, model, codebooks);
        succ('DONE in %f sec', toc(tmp));
        if params.use_calibration
            scores = adjust_scores(params, fit_params, scores);

            matches = scores > -0.25;
        else
            matches = true([1 length(scores)]);
        end
        info('Found matches for %s: %d', model.curid, sum(matches));
        scores = scores(matches);
        mimg = images(matches);
        umimg = unique(mimg);
        mbbs = bboxes(matches, :);

        [scores, idx] = sort(scores, 'descend');
        mimg = mimg(idx);
        mbbs = round(mbbs(idx, :));
        result = struct;
        if ~isempty(scores)
            result = alloc_struct_array(length(scores), 'curid', 'query_curid', 'img', 'patch', 'score', 'bbox', 'filename');
            result(length(scores)).query_curid = model.curid;
        end

        if params.use_calibration
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
                for pi=1:length(ioscores)
                    si = image_only(idx(pi));
                    bbs = iobbs(pi, :);
                    bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;
                    %I2 = I(bbs(2):bbs(4), bbs(1):bbs(3), :);
                    blend_mask = true([size(I, 1) size(I, 2)]);
                    blend_mask(bbs(2):bbs(4), bbs(1):bbs(3)) = false;
                    overlay = zeros([size(I, 1) size(I, 2)], 'uint8');
                    I2 = alpha_blend(I, overlay, 0.4, blend_mask);
                    %I2 = I(bbs(1):bbs(3), bbs(2):bbs(4), :);

                    filename = sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, ioscores(pi), image, pi);
                    imwrite(I2, filename);

                    result(si).query_curid = model.curid;
                    result(si).curid = database(image).curid;
                    result(si).img = image;
                    result(si).patch = pi;
                    result(si).score = ioscores(pi);
                    result(si).bbox = bbs;
                    result(si).filename = filename;
                end
            end
        else
            scores2 = [];
            bbs2 = [];
            images2 = [];
            resnum = [];
            patches = [];
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
                resnum = [resnum; image_only(idx)];
                patches = [patches, 1:length(ioscores)];
            end
            [scores2, idx] = sort(scores2, 'descend');

            % first 100
            scores2 = scores2(1:min([100, length(scores2)]));
            idx = idx(1:min([100, length(idx)]));

            bbs2 = bbs2(idx, :);
            images2 = images2(idx);
            resnum = resnum(idx);
            patches = patches(idx);

            for i=1:length(resnum)
                si = resnum(i);
                pi = patches(i);
                image = images2(i);
                I = get_image(params, database(image).curid);
                bbs = bbs2(i, :);
                bbs([3 4]) = bbs([3 4]) + bbs([1 2]) - 1;
                %I2 = I(bbs(2):bbs(4), bbs(1):bbs(3), :);
                blend_mask = true([size(I, 1) size(I, 2)]);
                blend_mask(bbs(2):bbs(4), bbs(1):bbs(3)) = false;
                overlay = zeros([size(I, 1) size(I, 2)], 'uint8');
                I2 = alpha_blend(I, overlay, 0.4, blend_mask);
                %I2 = I(bbs(1):bbs(3), bbs(2):bbs(4), :);

                filename = sprintf('%s/%05d-%.3f-Image%d-Patch%d.jpg', target_dir, si, scores2(i), image, pi);
                imwrite(I2, filename);

                result(si).query_curid = model.curid;
                result(si).curid = database(image).curid;
                result(si).img = image;
                result(si).patch = pi;
                result(si).score = scores2(i);
                result(si).bbox = bbs;
                result(si).filename = filename;
            end
        end

        % remove all empty results
        if ~isempty(result) && isfield(result, 'curid')
            result = result(~cellfun(@isempty, {result.curid}));
            results{mi} = result;
        else
            err('No results for %s', model.curid);
        end
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

    if false
        % TODO get all codebooks for the window list
        windows = calc_windows(params, size(I, 2), size(I, 1));
        % wrong
        %roi_size = query_file.bbox([3 4]) - query_file.bbox([1 2]) + 1;
        %codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size );
    else
        codebooks = get_codebooks(params, [], cluster_model);
        if ~isstruct(codebooks)
            features = prepare_features(params, {query_file});
            codebooks = get_codebooks(params, features, cluster_model);
            clear features;
        end
    end
    codebooks = double(horzcat(codebooks.I));


    fit_params = zeros([length(svm_models) 2]);
    for mi=1:length(svm_models)
        svm_model = svm_models(mi);

        scores = svm_model.classify(params, svm_model, codebooks);
        fit_params(mi, :) = estimate_fit_params(params, scores);
        %debg('Fitted \u03BC=%f \u03C3=%f', fit_params(1, 1), fit_params(1, 2));
        %debg('Fitted \xce\xbc=%f \xce\xc3=%f', fit_params(1, 1), fit_params(1, 2));
        debg('Fitted mu=%f sigma=%f', fit_params(1, 1), fit_params(1, 2));
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
        windows = calc_windows(params, features.I_size(2), features.I_size(1));
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
        debg('First zero: %d (%f)', zero, scores(zero));
        nonzero = find(matching, 1, 'last');
        debg('Last non-zero: %d (%f)', nonzero, scores(nonzero));
        remaining_scores = scores(matching);
        debg('Min: %f Mean: %f Max: %f', min(remaining_scores), mean(remaining_scores), max(remaining_scores));
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

    if params.expand_bboxes
        expand_bbs = 'expanded';
    else
        expand_bbs = 'nonexpanded';
    end

    if params.precalced_windows
        int_backend = 'window';
    elseif params.naiive_integral_backend
        int_backend = 'naiive';
    else
        if params.use_kdtree
            int_backend = 'sparse_kd';
        elseif params.integral_backend_sum
            int_backend = 'sparse_sum';
        elseif params.integral_backend_overwrite
            int_backend = 'sparse_overwrite';
        elseif params.integral_backend_matlab_sparse
            int_backend = 'sparse_matlab';
        else
            int_backend = 'sparse';
        end
    end

    if params.use_libsvm_classification
        scoring = 'libsvm';
    else
        scoring = 'matlab';
    end

    if params.window_prefilter
        filter = 'window';
    elseif params.inverse_search
        filter = 'inverse';
    else
        filter = 'no';
    end

    target_dir = [params.dataset.localdir filesep 'queries' filesep 'scaled'...
                filesep filter '-Filter'...
                filesep scoring '-Scoring'...
                filesep int_backend '-Backend'...
                filesep num2str(params.clusters) '-Cluster'...
                filesep num2str(params.parts) '-Parts'...
                filesep num2str(params.stream_max) '-Imgs' filesep...
                num2str(params.integrals_scale_factor) '-IntScale' filesep...
                params.codebook_type filesep...
                num2str(params.codebook_scales_count) '-NumScales' filesep...
                'nonmax-' nonmax_type filesep calib_type filesep...
                num2str(params.features_per_roi) '-featPerRoi' filesep...
                'querysrc-' query_src filesep expand_bbs '-bbs' filesep...
                curid];
end

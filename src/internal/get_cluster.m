function model = get_cluster( params, features )
%GET_CLUSTER Clusters the given features with kmeans
%
%   Syntax:     model = get_cluster( params, features )
%
%   Input:
%       params - The configuration struct used for caching and profiling
%       features - The feature struct array (Required Fields: X)
%
%   Output:
%       model - The computed model (Fields: centroids. Methods: feature2codebook(params, feature), feature2codebookintegral(params, feature))

    if ~isfield(params, 'dataset')
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    elseif isfield(params.dataset,'localdir') ...
          && ~isempty(params.dataset.localdir)
        CACHE_FILE = 1;
    else
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    end

    basedir = sprintf('%s/models/clusters/', params.dataset.localdir);
    if CACHE_FILE == 1 && ~exist(basedir,'dir')
        mkdir(basedir);
    end

    cachename = sprintf('%s/%d-%s-%s-%d.mat',...
                     basedir, params.clusters, params.class,...
                     params.stream_name, params.stream_max);

    if CACHE_FILE && fileexists(cachename)
        model = load_ex(cachename);
        model.feature2codebook = @(p,f,varargin)(feature2codebook(model, p, f, varargin{:}));
        if params.naiive_integral_backend
            model.feature2codebookintegral = @(p,f,varargin)(feature2codebookintegral_naiive(model, p, f, varargin{:}));
        else
            model.feature2codebookintegral = @(p,f,varargin)(feature2codebookintegral(model, p, f, varargin{:}));
        end
        fprintf(1,'get_cluster: length of stream=%05d\n', length(features));
        return;
    end

    if isempty(features)
        model = [];
        return;
    end


    tmp = tic;
    % struct array -> concat of field X
    features = single(vertcat(features.X))';
    info('Clustering %d features...', size(features, 2));
    model.centroids = yael_kmeans(features, params.clusters)';
    sec = toc(tmp);
    succ('DONE in %f sec', sec);

    if CACHE_FILE == 1
        save(cachename, '-struct', 'model');
    end

    % prevent saving of function handles
    model.feature2codebook = @(p,f)(feature2codebook(model, p,f));
    if params.naiive_integral_backend
        model.feature2codebookintegral = @(p,f)(feature2codebookintegral_naiive(model, p,f));
    else
        model.feature2codebookintegral = @(p,f)(feature2codebookintegral(model, p,f));
    end
end

function codebook = feature2codebook(model, params, feature)
%FEATURE2CODEBOOK Calculates a codebook from a given feature struct
%
%   Syntax:     codebook = feature2codebook(params, feature, model)
%
%   Input:
%       params - The configuration struct. Required fields: parts, codebook_type, profile (if profiling is required)
%       feature - The feature struct. Required fields: X, window2feature, bbs
%       model - The cluster model. Required fields: centroids
%
%   Output:
%       codebook - A NxM matrix. N: params.parts * size(centroids, 1), M: length(window2feature)

    profile_log(params);
    codebook = zeros([size(model.centroids, 1) * params.parts length(feature.window2feature)]);
    if strcmp(params.codebook_type, 'single')
        codebook = single(codebook);
    end

    if ~isempty(feature.X)
        tmp = tic;
        bbs = round(feature.bbs);
        X = feature.X;
        window2feature = feature.window2feature;

        if ~exist('current_scales', 'var')
            current_scales = [];
        end
        if all(feature.I_size > feature.area([3 4])) % computation of area width & height not needed as I_size == max values
            [unique_scales, scale_sizes] = get_available_scales(params, feature);
            roi_size = feature.area([3 4]) - feature.area([1 2]) + 1;
            current_scales = get_current_scales_by_size(params, unique_scales, scale_sizes, roi_size);
        end

        if ~isempty(current_scales)
            current_scales = filter_feature_by_scale(current_scales, feature);
            X = X(current_scales, :);
            bbs = bbs(current_scales, :);
            for wi=1:length(window2feature)
                wf = window2feature{wi};
                window2feature{wi} = wf(current_scales, :);
            end
        end
        info('Searching clusters with %d features...', size(X, 1));
        [assignments, distances] = knnsearch(model.centroids, single(X));
        emptyWindows = 0;
        for win=1:length(window2feature)
            winFeatures = window2feature{win};
            if sum(winFeatures) > 0
                %Y = single(feature.X(winFeatures, :));
                winBBs = bbs(winFeatures, :);
                centers = [(winBBs(:, 1) + winBBs(:, 3))/2, (winBBs(:, 2) + winBBs(:, 4))/2];
                minX = min(winBBs(:, 1));
                minY = min(winBBs(:, 2));
                maxX = max(winBBs(:, 3));
                maxY = max(winBBs(:, 4));
                [xsteps, ysteps] = getParts(minX, minY, maxX, maxY, params.parts);
                for part=1:params.parts
                    %tmp2 = tic;
                    %fprintf('Filter features...');
                    partFeatures = centers(:,1) >= minX + xsteps(1, part);
                    partFeatures = partFeatures & (centers(:,1) <= minX + xsteps(2, part));
                    partFeatures = partFeatures & (centers(:,2) >= minY + ysteps(1, part));
                    partFeatures = partFeatures & (centers(:,2) <= minY + ysteps(2, part));

                    %Z = Y(partFeatures, :);
                    %sec = toc(tmp2);
                    %fprintf('%f sec. ', sec);
                    %fprintf('Searching clusters with %d of %d features, window %d/%d %d/%d...', sum(partFeatures), sum(winFeatures), win, length(feature.window2feature), part, params.parts);
                    %[IDX, D] = knnsearch(model.centroids, Z);
                    IDX = assignments(partFeatures);
                    D = distances(partFeatures);

                    % create vector by incrementing value @ clusters
                    for i=1:size(IDX, 1)
                        codebook(IDX(i) + (part - 1) * size(model.centroids,1), win) = codebook(IDX(i) + (part - 1) * size(model.centroids,1), win) + 1 / D(i);
                    end
                    %sec = toc(tmp2);
                    %fprintf('DONE after %f sec\nFound %d unique clusters\n', sec, size(unique(IDX), 1));
                end
            else
                %warning('Empty window %d', win);
                emptyWindows = emptyWindows + 1;
            end
        end
        profile_log(params);

        sec = toc(tmp);
        succ('DONE in %f sec', sec);
        if emptyWindows > 0
            warn('%d out of %d windows were empty!', emptyWindows, length(window2feature));
        end
    end
end

function [codebook, scales] = feature2codebookintegral_naiive(model, params, feature)
%FEATURE2CODEBOOK Calculates a codebook integral from a given feature struct
%
%   Syntax:     codebook = feature2codebookintegral(params, feature, model)
%
%   Input:
%       params - The configuration struct. Required fields: codebook_type, profile (if profiling is required)
%       feature - The feature struct. Required fields: X, bbs, I_size, scales
%       model - The cluster model. Required fields: centroids
%
%   Output:
%       codebook - A SxNxWxH matrix. S: different scales, N: size(centroids, 1), W: I_size(2), H: I_size(1)
%       scales - A Cell of size S containing the associated scales.

    profile_log(params);

    codebook = zeros([params.codebook_scales_count size(model.centroids, 1) feature.I_size(2) feature.I_size(1)]);
    scales = cell([1 params.codebook_scales_count]);
    if strcmp(params.codebook_type, 'single')
        codebook = single(codebook);
    end

    if ~isempty(feature.X)
        bbs = round(feature.bbs);
        x = round((bbs(:, 1) + bbs(:, 3)) / 2);
        y = round((bbs(:, 2) + bbs(:, 4)) / 2);
        [unique_scales, scale_sizes] = get_available_scales(params, feature);
        for si=1:params.codebook_scales_count
            current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes);
            scales{si} = current_scales;

            current_scales = filter_feature_by_scale(current_scales, feature);
            Y = feature.X(current_scales, :);
            info('Searching clusters @ scale %d with %d features...', si, size(Y, 1));
            tmp = tic;
            [IDX, D] = knnsearch(model.centroids, single(Y));
            sec = toc(tmp);
            succ('DONE in %fs', sec);
            debg('Found %d unique cluster', size(unique(IDX), 1));

            info('Building codebooks...');
            tmp = tic;
            x2 = x(current_scales);
            y2 = y(current_scales);
            for i=1:size(IDX, 1)
                codebook(si, IDX(i), x2(i), y2(i)) = codebook(si, IDX(i), x2(i), y2(i)) + 1 / D(i);
            end
            sec = toc(tmp);
            succ('DONE in %fs', sec);
        end
        codebook = cumsum(codebook, 3);
        codebook = cumsum(codebook, 4);
    end
    profile_log(params);
end

function [codebook, scales] = feature2codebookintegral(model, params, feature)
%FEATURE2CODEBOOK Calculates a codebook integral from a given feature struct
%
%   Syntax:     codebook = feature2codebookintegral(params, feature, model)
%
%   Input:
%       params - The configuration struct. Required fields: codebook_type, profile (if profiling is required)
%       feature - The feature struct. Required fields: X, bbs, I_size, scales
%       model - The cluster model. Required fields: centroids
%
%   Output:
%       codebook - A SxNxWxH matrix. S: different scales, N: size(centroids, 1), W: I_size(2), H: I_size(1)
%       scales - A Cell of size S containing the associated scales.

    profile_log(params);

    codebook = zeros([params.codebook_scales_count size(model.centroids, 1) feature.I_size(2) feature.I_size(1)]);
    scales = cell([1 params.codebook_scales_count]);
    if strcmp(params.codebook_type, 'single')
        codebook = single(codebook);
    end

    if ~isempty(feature.X)
        bbs = round(feature.bbs);
        x = round((bbs(:, 1) + bbs(:, 3)) / 2);
        y = round((bbs(:, 2) + bbs(:, 4)) / 2);
        [unique_scales, scale_sizes] = get_available_scales(params, feature);
        for si=1:params.codebook_scales_count
            current_scales = get_current_scales_by_index(si, unique_scales, scale_sizes);
            scales{si} = current_scales;

            current_scales = filter_feature_by_scale(current_scales, feature);
            Y = feature.X(current_scales, :);
            info('Searching clusters @ scale %d with %d features...', si, size(Y, 1));
            tmp = tic;
            [IDX, D] = knnsearch(model.centroids, single(Y));
            sec = toc(tmp);
            succ('DONE in %fs', sec);
            debg('Found %d unique cluster', size(unique(IDX), 1));

            info('Building codebooks...');
            tmp = tic;
            x2 = x(current_scales);
            y2 = y(current_scales);
            for i=1:size(IDX, 1)
                codebook(si, IDX(i), x2(i), y2(i)) = codebook(si, IDX(i), x2(i), y2(i)) + 1 / D(i);
            end
            sec = toc(tmp);
            succ('DONE in %fs', sec);
        end
        info('Create integral image')
        tmp = tic;

        if ~params.integral_backend_sum
            codebook = cumsum(codebook, 3);
            codebook = cumsum(codebook, 4);
             if ~params.naiive_integral_backend && ~params.integral_backend_matlab_sparse
                % detect difference to previous
                if params.integral_backend_overwrite || params.use_kdtree
                    I3 = circshift(codebook, [0 0 1 1]);
                    I3(:, :, 1, :) = 0;
                    I3(:, :, :, 1) = 0;
                    unchanged = codebook == I3;
                    
%                     I3 = circshift(codebook, [0 0 1 0]);
%                     I3(:, :, 1, :) = 0;
%                     unchanged = unchanged | codebook == I3;
                    I3 = circshift(codebook, [0 0 0 1]);
                    I3(:, :, :, 1) = 0;
                    unchanged = unchanged | codebook == I3;
                else
                    % remove only changes in y direction
                    I3 = circshift(codebook, [0 0 1 0]);
                    I3(:, :, 1, :) = 0;
                    unchanged = codebook == I3;
                end

                codebook(unchanged) = 0;
                debg('Removed %d entries', sum(unchanged(:)));
            end
        end
        succ('Done in %fs', toc(tmp));
    end
    profile_log(params);
end

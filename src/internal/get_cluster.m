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
        fprintf(1,'Loading %s...',cachename);
        start = tic;
        model = load(cachename);
        sec = toc(start);
        fprintf(1, '%f sec\n', sec);
        model.feature2codebook = @(p,f)(feature2codebook(p,f,model));
        model.feature2codebookintegral = @(p,f)(feature2codebookintegral(p,f,model));
        fprintf(1,'get_cluster: length of stream=%05d\n', length(features));
        return;
    end


    tmp = tic;
    % struct array -> concat of field X
    features = single(vertcat(features.X))';
    fprintf('Clustering %d features...', size(features, 2));
    model.centroids = yael_kmeans(features, params.clusters)';
    sec = toc(tmp);
    fprintf('DONE in %f sec\n', sec);

    if CACHE_FILE == 1
        save(cachename, '-struct', 'model');
    end

    % prevent saving of function handles
    model.feature2codebook = @(p,f)(feature2codebook(p,f,model));
    model.feature2codebookintegral = @(p,f)(feature2codebookintegral(p,f,model));
end

function codebook = feature2codebook(params, feature, model)
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
        splitX = floor(sqrt(params.parts));
        splitY = ceil(sqrt(params.parts));
        fprintf('Searching clusters with %d features...', size(feature.X, 1));
        [assignments, distances] = knnsearch(model.centroids, single(feature.X));
        emptyWindows = 0;
        for win=1:length(feature.window2feature)
            winFeatures = feature.window2feature{win};
            if sum(winFeatures) > 0
                %Y = single(feature.X(winFeatures, :));
                winBBs = bbs(winFeatures, :);
                minX = min(winBBs(:, 1));
                minY = min(winBBs(:, 2));
                maxX = max(winBBs(:, 3));
                maxY = max(winBBs(:, 4));
                [xsteps, ysteps] = getParts(minX, minY, maxX, maxY, params.parts);
                for part=1:params.parts
                    %tmp2 = tic;
                    %fprintf('Filter features...');
                    partMinFeatures = winBBs(:,1) >= minX + xsteps(1, part);
                    partMinFeatures = partMinFeatures & (winBBs(:,1) <= minX + xsteps(2, part));
                    partMinFeatures = partMinFeatures & (winBBs(:,2) >= minY + ysteps(1, part));
                    partMinFeatures = partMinFeatures & (winBBs(:,2) <= minY + ysteps(2, part));
                    partMaxFeatures = winBBs(:,3) >= minX + xsteps(1, part);
                    partMaxFeatures = partMaxFeatures & (winBBs(:,3) <= minX + xsteps(2, part));
                    partMaxFeatures = partMaxFeatures & (winBBs(:,4) >= minY + ysteps(1, part));
                    partMaxFeatures = partMaxFeatures & (winBBs(:,4) <= minY + ysteps(2, part));
                    partFeatures = partMinFeatures | partMaxFeatures;

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
        fprintf('DONE in %f sec\n', sec);
        fprintf('%d out of %d windows were empty!\n', emptyWindows, length(feature.window2feature));
    end
end



function codebook = feature2codebookintegral(params, feature, model)
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
%       codebook - A SxNxWxH matrix. S: currently 1, N: size(centroids, 1), W: I_size(2), H: I_size(1)

    profile_log(params);
    % TODO: allow multiple scales
    params.NUM_SCALES = 1;

    codebook = zeros([params.NUM_SCALES size(model.centroids, 1) feature.I_size(2) feature.I_size(1)]);
    if strcmp(params.codebook_type, 'single')
        codebook = single(codebook);
    end

    if ~isempty(feature.X)
        bbs = round(feature.bbs);
        unique_scales = unique(feature.scales);
        scale_sizes = size(unique_scales, 2) / params.NUM_SCALES;
        for si=1:params.NUM_SCALES
            current_scales = ismember(feature.scales, unique_scales((si-1)*scale_sizes+1:si*scale_sizes));
            Y = feature.X(current_scales, :);
            fprintf('Searching clusters @ scale %d with %d features...', si, size(Y, 1));
            tmp = tic;
            [IDX, D] = knnsearch(model.centroids, single(Y));
            sec = toc(tmp);
            fprintf('DONE in %fs\nFound %d unique clusters\n', sec, size(unique(IDX), 1));

            fprintf('Building codebooks...');
            tmp = tic;
            for i=1:size(IDX, 1)
                codebook(si, IDX(i), bbs(i, 3), bbs(i, 4)) = codebook(si, IDX(i), bbs(i, 3), bbs(i, 4)) + 1 / D(i);
            end

            codebook = cumsum(codebook, 3);
            codebook = cumsum(codebook, 4);
            sec = toc(tmp);
            fprintf('DONE in %fs\n', sec);
        end
    end
    profile_log(params);
end

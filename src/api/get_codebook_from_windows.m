function images = get_codebook_from_windows(params, features, cluster_model, roi_size)
%GET_CODEBOOK_FROM_WINDOWS Get images codebooks from given features
%
%   Syntax:     images = get_codebook_from_windows(params, features, cluster_model, roi_size)
%
%   Input:
%       params - Configuration struct
%       features - A feature struct array. Required Fields: curid, X, bbs, I_size, scales
%       cluster_model - A model from get_cluster
%       roi_size - Size of the query part
%
%   Output:
%       images - A struct array with fields: curid, scale_factor, max_size,
%                                            min_size, bboxes, codebooks, images

    profile_log(params);
    % cache
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



    scale_factor = max([0, min([1, params.integrals_scale_factor])]);
    if ~exist('roi_size', 'var')
        roi_size = [];
    end
    cachename = get_cache_name(params, roi_size, CACHE_FILE);


    if CACHE_FILE && fileexists(cachename)
        if nargout > 0
            load_ex(cachename);
            fprintf(1,'get_codebook_from_windows: length of stream=%05d\n', length(features));
        end
        return;
    end

    if isempty(features)
        warn('No features given to get_codebook_integrals and no cache present @ %s', cachename);
        warning('No features given to get_codebook_integrals and no cache present @ %s', cachename);
        images = [];
        return;
    end

    integral_count = params.codebook_scales_count;
    if ~isempty(roi_size) && params.stream_max == 1
        integral_count = 1;
    end

    bbs = cat(1, features.bbs);
    bbs(:, [3 4]) = bbs(:, [3 4]) - bbs(:, [1 2]) + 1;
    windows = calc_windows(params, max(bbs(:, 3)), max(bbs(:, 4)), 32, 32);
    ratios = ones([size(windows, 1), 1]) * 1;
    windows = [windows; calc_windows(params, max(bbs(:, 3)), max(bbs(:, 4)), 16, 32)];
    ratios = [ratios; ones([size(windows, 1) - size(ratios, 1), 1]) * 16/32];
    windows = [windows; calc_windows(params, max(bbs(:, 3)), max(bbs(:, 4)), 32, 16)];
    ratios = [ratios; ones([size(windows, 1) - size(ratios, 1), 1]) * 32/16];
    windows = [windows; calc_windows(params, max(bbs(:, 3)), max(bbs(:, 4)), 32, 24)];
    ratios = [ratios; ones([size(windows, 1) - size(ratios, 1), 1]) * 32/24];
    windows = [windows; calc_windows(params, max(bbs(:, 3)), max(bbs(:, 4)), 24, 32)];
    ratios = [ratios; ones([size(windows, 1) - size(ratios, 1), 1]) * 24/32];
    debg('%d total windows per image', size(windows, 1));

    images = alloc_struct_array({integral_count, length(features)}, 'curid', 'scale_factor', 'max_size', 'min_size', 'bboxes', 'codebooks', 'images');
    for fi=1:length(features)
        feature = features(fi);

        imgcachename = get_img_cache_name(params, feature, roi_size, CACHE_FILE);

        if CACHE_FILE
            try
                files = get_possible_cache_files(imgcachename);
            catch
                % no files found
                files = [];
            end

            if length(files) == params.codebook_scales_count
                image = struct;
                [files, sizes] = sort_cache_files(files, imgcachename);
                if ~isempty(roi_size) && params.stream_max == 1
                    filename = filter_cache_files(params, files, sizes, roi_size);
                    files = {filename};
                end

                for ci=1:length(files)
                    load_ex(files{ci});
                    images(ci, fi) = orderfields(image);
                end

                continue;
            end
        end

        [I, scales] = cluster_model.feature2codebookintegral(params, feature);

        for si=1:length(scales)
            I2 = I(si, :, :, :);

            s = size(I2);
            w = s(3);
            h = s(4);

            subset = windows(:, 1) < w & windows(:, 2) < h;
            imgRatios = ratios(subset);
            imgWindowsBB = windows(subset, :);
            %imgWindowsBB = max(imgWindowsBB, 0);
            imgWindowsBB(:, 3) = min(imgWindowsBB(:, 3), w);
            imgWindowsBB(:, 4) = min(imgWindowsBB(:, 4), h);

            [imgWindowsBB, idx] = unique(imgWindowsBB, 'rows');
            imgRatios = imgRatios(idx);
            params.naiive_integral_backend = true;
            integralImg.I = I;

            codebooks3 = getCodebooksFromIntegral(params, integralImg, imgWindowsBB, params.parts);
            [cbdim, scales2, cbnum] = size(codebooks3);

            % amount * scales x codebook
            codebooks2 = zeros([cbnum * scales2, cbdim]);
            pos = 1;
            for si2=1:scales2
                codebooks2(pos:pos+cbnum-1, :) = reshape(codebooks3(:, si2, :), [cbdim cbnum])';
                pos = pos + cbnum-1;
            end
            % amount * scales x 4
            % is sync with codebooks2??
            imgWindowsBB = repmat(imgWindowsBB, scales2, 1);
            imgRatios = repmat(imgRatios, scales2, 1);

            % is a codebook with 0 entries valid?
            valid_codebooks = any(codebooks2, 2);

            debg('%d/%d removed...', sum(~valid_codebooks), size(codebooks2, 1));

            codebooks2(~valid_codebooks, :) = [];

            if isempty(codebooks2)
                err('No codebooks for %s?\n', filename);
                continue;
                %error('No codebooks for %s?\n', filename);
            end

            images(si, fi).bboxes = imgWindowsBB(valid_codebooks, :);
            images(si, fi).ratios = imgRatios(valid_codebooks);
            images(si, fi).codebooks = codebooks2;
            images(si, fi).curid = feature.curid;
            current_scales = scales{si};
            [ min_size, max_size ] = get_range_for_scale(params, current_scales);
            images(si, fi).max_size = max_size;
            images(si, fi).min_size = min_size;
        end


        if CACHE_FILE
            for si=1:length(scales)
                image2 = images(si, fi);
                uratios = unique(image2.ratios);
                for ri=1:length(uratios)
                    image = image2;
                    idx = image.ratios ~= uratios(ri);
                    image.bboxes(idx,:) = [];
                    image.codebooks(idx,:) = [];
                    image.ratios(idx) = [];
                    save_ex(sprintf(imgcachename, uratios(ri), image.max_size(1), image.max_size(2)), 'image');
                end
            end
        end
    end
    profile_log(params);

    if CACHE_FILE && size(images, 2) > 1
        orig_images = images;
        for si=1:size(orig_images, 1)
            images2 = orig_images(si, :);
            uratios = unique(vertcat(images2.ratios));
            for ri=1:length(uratios)
                images = images2;
                for ii=1:size(images, 2)
                    idx = images(ii).ratios ~= uratios(ri);
                    images(ii).bboxes(idx,:) = [];
                    images(ii).codebooks(idx,:) = [];
                    images(ii).ratios(idx) = [];
                end
                tmp = max(vertcat(images.max_size));
                save_ex(sprintf(cachename, uratios(ri), tmp(1), tmp(2)), 'images');
            end
        end

        if ~isempty(roi_size)
            cachename2 = get_cache_name(params, roi_size, CACHE_FILE);

            for si=1:size(orig_images, 1)
                images = orig_images(si, :);
                tmp = max(vertcat(images.max_size));
                if strcmp(sprintf(cachename, tmp(1), tmp(2)), cachename2)
                    break
                end
            end
        end
    end
end

function basedir = get_cache_basedir(params, create_dir)
%GET_CACHE_BASEDIR Gets and creates the cache dir
%
%   Syntax:     basedir = get_cache_basedir(params, create_dir)
%
%   Input:
%       params - Configuration struct
%       create_dir - Boolean to indicate the automatic creation of the dir
%
%   Output:
%       basedir - The cache dir

    basedir = sprintf('%s/models/codebooks/windowed/', params.dataset.localdir);
    if create_dir && ~exist(basedir,'dir')
        mkdir(basedir);
    end
end

function cachename = get_cache_name(params, roi_size, create_dir)
%GET_CACHE_NAME Gets the cache filename
%
%   Syntax:     cachename = get_cache_name(params, roi_size, create_dir)
%
%   Input:
%       params - Configuration struct
%       roi_size - Vector containing the size of the roi or empty
%       create_dir - Boolean to indicate the automatic creation of the dir
%
%   Output:
%       cachename - The cache file name

    if isfield(params, 'feature_type')
        type = params.feature_type;
    else
        type = 'bboxed';
    end

    basedir = get_cache_basedir(params, create_dir);

    scale_factor = max([0, min([1, params.integrals_scale_factor])]);
    if params.codebook_scales_count > 1
        cachename = sprintf('%s/%%f/%d-%s-%s-%s-%d-%.3f-%s-%d-%%dx%%d.mat',...
                         basedir, params.clusters, params.class,...
                         type, params.stream_name, params.stream_max,...
                         scale_factor, params.codebook_type, params.codebook_scales_count);

        if ~isempty(roi_size)
            ratio = roi_size(1) / roi_size(2);
            ratios = [0.5, 0.75, 1, 1.333333, 2];
            ratios2 = abs(ratios - ratio);
            [~, idx] = min(ratios2);
            cachename = sprintf(strrep(cachename, '%d', '%%d'), ratios(idx));
            try
                files = get_possible_cache_files(cachename);
            catch
                % prevent loading
                %cachename = strrep(cachename, '*', '%d');
                return;
            end

            %cachename = strrep(cachename, '*', '%d');
            [files, sizes] = sort_cache_files(files, cachename);
            cachename = filter_cache_files(params, files, sizes, roi_size);
        end
    else
        cachename = sprintf('%s/%%f/%d-%s-%s-%s-%d-%.3f.mat',...
                         basedir, params.clusters, params.class,...
                         type, params.stream_name, params.stream_max, scale_factor);

        if strcmp(params.codebook_type, 'single')
            cachename = sprintf('%s/%%f/%d-%s-%s-%s-%d-%.3f-single.mat',...
                             basedir, params.clusters, params.class,...
                             type, params.stream_name, params.stream_max, scale_factor);
        end
    end
end

function imgcachename = get_img_cache_name(params, feature, roi_size, create_dir)
%GET_IMG_CACHE_NAME Gets the cache filename of a single image
%
%   Syntax:     imgcachename = get_img_cache_name(params, roi_size, create_dir)
%
%   Input:
%       params - Configuration struct
%       roi_size - Vector containing the size of the roi or empty
%       create_dir - Boolean to indicate the automatic creation of the dir
%
%   Output:
%       imgcachename - The cache file name

    if isfield(params, 'feature_type')
        type = params.feature_type;
    else
        type = 'bboxed';
    end

    basedir = get_cache_basedir(params, create_dir);
    detaildir = sprintf('%s/images/', basedir);
    if create_dir && ~exist(detaildir,'dir')
        mkdir(detaildir);
    end

    scale_factor = max([0, min([1, params.integrals_scale_factor])]);
    if params.codebook_scales_count > 1
        imgcachename = sprintf('%s/%%f/%d-%s-%s-%d-%s-%.3f-%s-%d-%%dx%%d.mat',...
                         detaildir, params.clusters, params.class,...
                         feature.curid, feature.objectid, type, scale_factor,...
                         params.codebook_type, params.codebook_scales_count);
    else
        imgcachename = sprintf('%s/%%f/%d-%s-%s-%d-%s-%.3f.mat',...
                               detaildir, params.clusters, params.class,...
                               feature.curid, feature.objectid, type, scale_factor);

        if strcmp(params.codebook_type, 'single')
            imgcachename = sprintf('%s/%%f/%s-%%d-s-%d-%s-%.3f-single.mat',...
                               detaildir, params.clusters, params.class,...
                               feature.curid, feature.objectid, type, scale_factor);
        end
    end
    if ~isempty(roi_size)
        ratio = roi_size(1) / roi_size(2);
        ratios = [0.5, 0.75, 1, 1.333333, 2];
        ratios2 = abs(ratios - ratio);
        [~, idx] = min(ratios2);
        imgcachename = sprintf(strrep(imgcachename, '%d', '%%d'), ratios(idx));
    end
end

function integrals = get_codebook_integrals(params, features, cluster_model, roi_size)
%GET_CODEBOOK_INTEGRALS Get integral codebooks from given features
%
%   Syntax:     integrals = get_codebook_integrals(params, features, cluster_model)
%
%   Input:
%       params - Configuration struct
%       features - A feature struct array. Required Fields: curid, X, bbs, I_size, scales
%       cluster_model - A model from get_cluster
%
%   Output:
%       integrals - A struct array with fields: I, curid, scale_factor,
%                   min_size, max_size

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
        load_ex(cachename);
        if ~isfield(integrals, 'scale_factor')
            [integrals.scale_factor] = deal(1);
        end
        fprintf(1,'get_codebook_integrals: length of stream=%05d\n', length(features));
        return;
    end
    
    if isempty(features)
        error('No features given to get_codebook_integrals and no cache present @ %s', cachename);
    end

    integral_count = params.codebook_scales_count;
    if ~isempty(roi_size)
        integral_count = 1;
    end
    integrals = alloc_struct_array({integral_count, length(features)}, 'I', 'curid', 'scale_factor', 'max_size', 'min_size');
    for fi=1:length(features)
        feature = features(fi);

        imgcachename = get_img_cache_name(params, feature, roi_size, CACHE_FILE);

        if CACHE_FILE
            try
                files = get_possible_cache_files(imgcachename);
                if length(files) == params.codebook_scales_count
                    integral = struct;
                    [files, ~] = sort_cache_files(files, imgcachename);
                    if ~isempty(roi_size)
                        filename = filter_cache_files(params, files, sizes, roi_size);
                        files = {filename};
                    end
                    
                    for ci=1:length(files)
                        load_ex(files{ci});
                        if ~isfield(integral, 'scale_factor')
                            integral.scale_factor = 1;
                        end
                        bbs = feature.bbs;
                        bbs(:, [3 4]) = bbs(:, [3 4]) - bbs(:, [1 2]) + 1;
                        if ~isfield(integral, 'max_size')
                            integral.max_size = max(bbs(:, [3 4]));
                        end
                        if ~isfield(integral, 'min_size')
                            integral.min_size = min(bbs(:, [3 4]));
                        end
                        integrals(ci, fi) = integral;
                    end
                
                    continue;
                end
            catch
                % no files found
            end
        end
        
        [I, scales] = cluster_model.feature2codebookintegral(params, feature);
        if scale_factor < 1 && scale_factor > 0
            deleteEveryN = 1 / (1 - scale_factor);
            fprintf(' Rescaling: %.3f, deleting every %d\n', scale_factor, deleteEveryN);
            % maybe not best method, but works approx
            % >> round(1:(1/(1-0.75)):10)
            % 1     5     9
            % >> round(1:(1/(1-0.5)):10)
            % 1     3     5     7     9
            % >> round(1:(1/(1-0.25)):10)
            % 1     2     4     5     6     8     9
            % >> round(1:(1/(1-2/3)):10)
            % 1     4     7     10
            deleteCols = round(1:deleteEveryN:size(I, 3));
            deleteRows = round(1:deleteEveryN:size(I, 4));
            I(:, :, deleteCols, :) = [];
            I(:, :, :, deleteRows) = [];
        end
        
        for si=1:length(scales)
            integrals(si, fi).I = I(si, :, :, :);
            integrals(si, fi).curid = feature.curid;
            integrals(si, fi).scale_factor = scale_factor;
            %bbs = feature.bbs(ismember(feature.scales, scales{si}), :);
            %bbs(:, [3 4]) = round(bbs(:, [3 4]) - bbs(:, [1 2]) + 1);
            %integrals(si, fi).max_size = max(bbs(:, [3 4]));
            %integrals(si, fi).min_size = min(bbs(:, [3 4]));
            current_scales = scales{si};
            [ min_size, max_size ] = get_range_for_scale(params, current_scales);
            integrals(si, fi).max_size = max_size;
            integrals(si, fi).min_size = min_size;
        end


        if CACHE_FILE
            for si=1:length(scales)
                integral = integrals(si, fi);
                save_ex(sprintf(imgcachename, integral.max_size(1), integral.max_size(2)), 'integral');
            end
        end
    end
    profile_log(params);

    if CACHE_FILE
        orig_integrals = integrals;
        for si=1:size(orig_integrals, 1)
            integrals = orig_integrals(si, :);
            tmp = max(vertcat(integrals.max_size));
            save_ex(sprintf(cachename, tmp(1), tmp(2)), 'integrals');
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

    basedir = sprintf('%s/models/codebooks/integral/', params.dataset.localdir);
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
        cachename = sprintf('%s/%s-%s-%s-%d-%.3f-%s-%d-%%dx%%d.mat',...
                         basedir, params.class,...
                         type, params.stream_name, params.stream_max,...
                         scale_factor, params.codebook_type, params.codebook_scales_count);
        
        if ~isempty(roi_size)
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
        cachename = sprintf('%s/%s-%s-%s-%d-%.3f.mat',...
                         basedir, params.class,...
                         type, params.stream_name, params.stream_max, scale_factor);

        if strcmp(params.codebook_type, 'single')
            cachename = sprintf('%s/%s-%s-%s-%d-%.3f-single.mat',...
                             basedir, params.class,...
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
        imgcachename = sprintf('%s/%s-%s-%d-%s-%.3f-%s-%d-%%dx%%d.mat',...
                         detaildir, params.class,...
                         feature.curid, feature.objectid, type, scale_factor,...
                         params.codebook_type, params.codebook_scales_count);
    else
        imgcachename = sprintf('%s/%s-%s-%d-%s-%.3f.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type, scale_factor);

        if strcmp(params.codebook_type, 'single')
            imgcachename = sprintf('%s/%s-%s-%d-%s-%.3f-single.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type, scale_factor);
        end
    end
end

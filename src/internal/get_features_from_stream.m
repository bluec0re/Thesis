function features = get_features_from_stream( params, stream )

    profile_log(params);
    if ~isfield(params, 'dataset')
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    elseif isfield(params.dataset,'localdir') ...
          && length(params.dataset.localdir)>0
        CACHE_FILE = 1;
    else
        params.dataset.localdir = '';
        CACHE_FILE = 0;
    end

    basedir = sprintf('%s/models/features/', params.dataset.localdir);
    if CACHE_FILE == 1 && ~exist(basedir,'dir')
        mkdir(basedir);
    end

    detaildir = sprintf('%s/images', basedir);
    if CACHE_FILE == 1 && ~exist(detaildir,'dir')
        mkdir(detaildir);
    end

    if isfield(params, 'feature_type')
        type = params.feature_type;
    else
        type = 'bboxed';
    end

    cachename = sprintf('%s/%s-%s-%s-%d.mat',...
                     basedir, params.class,...
                     type, params.stream_name, params.stream_max);

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename, 'features');
        fprintf(1,'get_features_from_stream: length of stream=%05d\n', length(features));
        return;
    end

    % struct array preallocate
    features = alloc_struct_array(length(stream), 'curid', 'objectid',...
                                      'feature_type', 'I_size', 'X', 'M',...
                                      'scales', 'bbs', 'window2feature',...
                                      'area');

    for streamid=1:length(stream)
        fprintf('image %04d/%04d...', streamid, length(stream));
        model = stream{streamid};

        if strcmp(type, 'full') % no difference in objects
            model.objectid = 0;
        end

        imagecachename = sprintf('%s/%s-%s-%d-%s.mat',...
                                 detaildir, params.class,...
                                 model.curid, model.objectid, type);

        % get field order
        feature = features(streamid);
        if CACHE_FILE && fileexists(imagecachename)
            load_ex(imagecachename, 'feature');
            features(streamid) = feature;
            continue;
        end

        feature.curid = model.curid;
        feature.objectid = model.objectid;
        feature.feature_type = type;

        I = convert_to_I(model.I);

        feature.I_size = [size(I, 1) size(I, 2)];

        t = get_pyramid(I, params.esvm_default_params);
        profile_log(params);

        if strcmp(type, 'bboxed')
            mask = false([size(I, 1) size(I, 2)]);
            mask(model.bbox(2):model.bbox(4), model.bbox(1):model.bbox(3)) = true;
            feature.area = model.bbox;
        elseif strcmp(type, 'full') || strcmp(type, 'full-masked')
            mask = true([size(I, 1) size(I, 2)]);
            if strcmp(type, 'full-masked')
                mask(model.bbox(2):model.bbox(4), model.bbox(1):model.bbox(3)) = false;
            end
            feature.area = [1 1 feature.I_size(2) feature.I_size(1)];
        end
        profile_log(params);

        [feature.X, W, feature.M, offsets, uus, vvs, feature.scales] = getHogsInsideBox(t, I, mask, params);
        profile_log(params);

        sbin = params.esvm_default_params.init_params.sbin;
        o = [uus' vvs'] - t.padder;
        feature.scales = feature.scales(offsets(2,:));
        feature.bbs = ([o(:,2) o(:,1) o(:,2) + 5 ...
            o(:,1)+ 5] - 1) .* ...
            repmat(sbin./feature.scales',1,4) + 1 + repmat([0 0 -1 -1],length(feature.scales),1);
        profile_log(params);

        if strcmp(type, 'full') || strcmp(type, 'full-masked')
            windows = calc_windows(size(I, 2), size(I, 1));

            featureIds = get_features_per_window(params, windows, feature.bbs);
            feature.window2feature = featureIds;
        else
            feature.window2feature{1} = true([size(feature.X, 2) 1]);
        end
        profile_log(params);
        if CACHE_FILE == 1
            save_ex(imagecachename, 'feature');
        end

        features(streamid) = feature;
        fprintf('\n');
    end

    % search duplicates
    if strcmp(type, 'full')
        ids = {features.curid};
        [~, unique_features] = unique(ids);
        fprintf(' Removed %d duplicates\n', length(features) - size(unique_features, 1));
        features = features(unique_features);
    end

    if CACHE_FILE == 1
        save_ex(cachename, 'features');
    end
end

function ids = get_features_per_window(params, windows, bboxes)
    profile_log(params);
    min_overlap = 0.5;
    ids = cell([size(windows, 1) 1]);
    for wi=1:size(windows, 1)
        window = windows(wi, :);
        w = window(3) - window(1) + 1;
        w = w * min_overlap;
        h = window(4) - window(2) + 1;
        h = h * min_overlap;

        % top left
        featuresTL = bboxes(:, 1) >= window(1) & bboxes(:, 1) <= window(3) - w;
        featuresTL = bboxes(:, 2) >= window(2) & bboxes(:, 2) <= window(4) - h & featuresTL;

        % bottom left
        featuresBL = bboxes(:, 1) >= window(1) & bboxes(:, 1) <= window(3) - w;
        featuresBL = bboxes(:, 4) >= window(2) + h & bboxes(:, 4) <= window(4) & featuresBL;

        % top right
        featuresTR = bboxes(:, 3) >= window(1) + w & bboxes(:, 3) <= window(3);
        featuresTR = bboxes(:, 2) >= window(2) & bboxes(:, 2) <= window(4) - h & featuresTR;

        % bottom right
        featuresBR = bboxes(:, 3) >= window(1) + w & bboxes(:, 3) <= window(3);
        featuresBR = bboxes(:, 4) >= window(2) + h & bboxes(:, 4) <= window(4) & featuresBR;

        ids{wi} = featuresTL | featuresBL | featuresTR | featuresBR;
    end
end

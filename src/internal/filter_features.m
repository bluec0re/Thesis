function features = filter_features(params, features)
%FILTER_FEATURES Filters given features
%   Removes features with too little texture or which are too close to the negative mode of whitened features
%
%   Syntax:     features = filter_features(params, features)
%
%   Input:
%       params - The configuration struct. Used for profiling and caching
%       features - The feature struct array (Fields: X, M, distVec, scales, bbs, window2feature)
%
%   Output:
%       features - The filtered feature struct array with new logical vector deletedFeatures

    profile_log(params);
    % cache
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

    if isfield(params, 'feature_type')
        type = params.feature_type;
    else
        type = 'bboxed';
    end

    cachename = sprintf('%s/%s-%s-%s-%d-filtered.mat',...
                     basedir, params.class,...
                     type, params.stream_name, params.stream_max);

    if CACHE_FILE && fileexists(cachename) && params.stream_max > 1
        load_ex(cachename, 'features');
        fprintf(1,'filter_features: length of stream=%05d\n', length(features));
        return;
    end
    
    if isempty(features)
        return;
    end

    for fid=1:length(features)
        feature = features(fid);
        features(fid).deletedFeatures = [];
        if ~isempty(feature.X)
            X = feature.X;
            G = feature.M;
            distVec = feature.distVec;
            fprintf('image %04d/%04d...', fid, length(features));

            % delete all features which contain to little texture
            gradientThresh = 25 / 255;
            deleteGradientBin = G' < gradientThresh;

            % delete all features which are too close to the negative mode
            negModeThresh = mean(distVec)-std(distVec);
            deleteNegativeModeBin = distVec < negModeThresh;
            deleteFeatureBin = or(deleteGradientBin,deleteNegativeModeBin);

            % filter
            features(fid).X = feature.X(~deleteFeatureBin,:);
            features(fid).bbs = feature.bbs(~deleteFeatureBin,:);
            features(fid).M = G(~deleteFeatureBin);
            features(fid).scales = feature.scales(~deleteFeatureBin);
            features(fid).distVec = distVec(~deleteFeatureBin);
            features(fid).deletedFeatures = deleteFeatureBin;
            for wi=1:length(feature.window2feature)
                mapping = feature.window2feature{wi};
                features(fid).window2feature{wi} = mapping(~deleteFeatureBin);
            end
        end
        fprintf('\n');
    end
    profile_log(params);

    if CACHE_FILE && params.stream_max > 1
        save_ex(cachename, 'features');
    end
end

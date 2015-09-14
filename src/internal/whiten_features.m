function features = whiten_features( params, features )
%WHITEN_FEATURES Transforms HoG features into whitened HoGs
%
%   Syntax:     features = whiten_features( params, features )
%
%   Input:
%       params - Configuration struct
%       features - Feature struct array. Required Fields: X, M
%
%   Output:
%       features - Whitened feature struct array. New Field: distVec

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

    cachename = sprintf('%s/%s-%s-%s-%d-whitened.mat',...
                     basedir, params.class,...
                     type, params.stream_name, params.stream_max);

    if CACHE_FILE && fileexists(cachename) && params.stream_max > 1
        load_ex(cachename, 'features');
        fprintf(1,'whiten_features: length of stream=%05d\n', length(features));
        return;
    end
    
    if isempty(features)
        return;
    end

    % neg model
    neg_model = get_neg_model(params);

    % calc
    for fid=1:length(features)
        feature = features(fid);
        features(fid).distVec = [];
        if ~isempty(feature.X)
            X = feature.X;
            G = feature.M;
            fprintf('image %04d/%04d...', fid, length(features));
            fmask = false([12 12 31]);
            fmask(1:5, 1:5, :) = true;
            covHog = neg_model.cov_hog(fmask(:), fmask(:));
            invCovHog = neg_model.invcov_hog(fmask(:), fmask(:));
            idx_diag = sub2ind(size(covHog), 1:size(covHog,1), 1:size(covHog,1));
            covHog(idx_diag) = covHog(idx_diag) + 0.001;
            [covA, covB] = chol(covHog); % sqrt

            meanHog = neg_model.mean(neg_model.idx_hog(fmask(:)));
            meanSubsFeats = bsxfun(@minus, X', meanHog);
            features(fid).X = meanSubsFeats/covA; % whitened HoG

            halfDist = meanSubsFeats*invCovHog; % LDA classifier
            fullDist = halfDist.*meanSubsFeats;
            distVec = sum(fullDist,2); % mahalanobis distance to the covariance cluster

            features(fid).distVec = distVec;
        end
        fprintf('\n');
    end
    profile_log(params);

    params.neg_model = neg_model;

    if CACHE_FILE && params.stream_max > 1
        save_ex(cachename, 'features');
    end
end

function neg_model = get_neg_model(params)
    if ~isfield(params, 'neg_model') || isempty(params.neg_model)
        neg_model = get_full_neg_model;
%         fprintf('loading Neg Model...');
%         start = tic;
%         neg_model = get_full_neg_model;
%         sec = toc(start);
%         fprintf(1, '%f sec\n', sec);
    else
        neg_model = params.neg_model;
    end
end

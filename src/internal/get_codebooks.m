function codebooks = get_codebooks(params, features, cluster_model)
%GET_CODEBOOKS Get integral codebooks from given features
%
%   Syntax:     codebooks = get_codebooks(params, features, cluster_model)
%
%   Input:
%       params - Configuration struct
%       features - A feature struct array. Required Fields: curid, X, bbs, window2feature
%       cluster_model - A model from get_cluster
%
%   Output:
%       codebooks - A struct array with fields: I, curid, size

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

    basedir = sprintf('%s/models/codebooks/plain/', params.dataset.localdir);
    if CACHE_FILE == 1 && ~exist(basedir,'dir')
        mkdir(basedir);
    end

    detaildir = sprintf('%s/images/', basedir);
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

    if strcmp(params.codebook_type, 'single')
        cachename = sprintf('%s/%s-%s-%s-%d-single.mat',...
                     basedir, params.class,...
                     type, params.stream_name, params.stream_max);
    end

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename);
        fprintf(1,'get_codebooks: length of stream=%05d\n', length(features));
        return;
    end

    codebooks = alloc_struct_array(length(features), 'I', 'curid', 'size');
    for fi=1:length(features)
        feature = features(fi);


        imgcachename = sprintf('%s/%s-%s-%d-%s.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type);
        if strcmp(params.codebook_type, 'single')
            imgcachename = sprintf('%s/%s-%s-%d-%s-single.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type);
        end

        codebook = codebooks(fi);
        if CACHE_FILE && fileexists(imgcachename)
            load_ex(imgcachename);
            cb.I = codebook.I;
            cb.curid = codebook.curid;
            cb.size = codebook.size;
            codebooks(fi) = cb;
            continue;
        end

        codebooks(fi).I = cluster_model.feature2codebook(params, feature);
        codebooks(fi).curid = feature.curid;
        codebooks(fi).size = feature.area([3 4]) - feature.area([1 2]) + 1;


        if CACHE_FILE
            codebook = codebooks(fi);
            save_ex(imgcachename, 'codebook');
        end
    end
    profile_log(params);

    if CACHE_FILE && length(codebooks) > 1
        save_ex(cachename, 'codebooks');
    end
end

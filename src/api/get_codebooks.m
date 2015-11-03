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
    [CACHE_FILE, params] = file_cache_enabled(params);

    if params.fisher_backend
        basedir = sprintf('%s/models/codebooks/fisher/plain/', params.dataset.localdir);
    else
        basedir = sprintf('%s/models/codebooks/plain/', params.dataset.localdir);
    end
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

    cachename = sprintf('%s/%d-%s-%s-%s-%d-%d.mat',...
                     basedir, params.clusters, params.class,...
                     type, params.stream_name, params.stream_max,...
                     params.parts);

    if strcmp(params.codebook_type, 'single')
        cachename = sprintf('%s/%d-%s-%s-%s-%d-%d-single.mat',...
                     basedir, params.clusters, params.class,...
                     type, params.stream_name, params.stream_max,...
                     params.parts);
    end

    if params.memory_cache && evalin('base', ['exist(''LAST_NEG_CB'', ''var'') && strcmp(LAST_NEG_CB, ''' cachename ''');'])
        debg('++ Using preloaded negative codebooks %s', cachename);
        codebooks = evalin('base', 'NEG_CB');
        return;
    end

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename);
        fprintf(1,'get_codebooks: length of stream=%05d\n', length(features));
        if params.memory_cache
            assignin('base', 'NEG_CB', codebooks);
            assignin('base', 'LAST_NEG_CB', cachename);
        end
        return;
    end

    if isempty(features)
        codebooks = [];
        return;
    end

    codebooks = alloc_struct_array(length(features), 'I', 'curid', 'size');
    for fi=1:length(features)
        feature = features(fi);


        imgcachename = sprintf('%s/%d-%s-%s-%d-%s-%d.mat',...
                               detaildir, params.clusters, params.class,...
                               feature.curid, feature.objectid, type,...
                               params.parts);
        if strcmp(params.codebook_type, 'single')
            imgcachename = sprintf('%s/%d-%s-%s-%d-%s-%d-single.mat',...
                               detaildir, params.clusters, params.class,...
                               feature.curid, feature.objectid, type,...
                               params.parts);
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
        if params.memory_cache
            assignin('base', 'NEG_CB', codebooks);
            assignin('base', 'LAST_NEG_CB', cachename);
        end
    end
end

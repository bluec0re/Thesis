function [ integrals ] = get_codebook_integrals(params, features, cluster_model)
%GET_CODEBOOKS Summary of this function goes here
%   Detailed explanation goes here

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

    basedir = sprintf('%s/models/codebooks/integral/', params.dataset.localdir);
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

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename);
        fprintf(1,'get_codebook_integrals: length of stream=%05d\n', length(features));
        return;
    end

    integrals = alloc_struct_array(length(features), 'I', 'curid');
    for fi=1:length(features)
        feature = features(fi);
        
        
        imgcachename = sprintf('%s/%s-%s-%d-%s.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type);

        integral = integrals(fi);
        if CACHE_FILE && fileexists(imgcachename)
            load_ex(imgcachename);
            integrals(fi) = integral;
            continue;
        end
        
        integrals(fi).I = cluster_model.feature2codebookintegral(params, feature);
        integrals(fi).curid = feature.curid;
        
        
        if CACHE_FILE
            integral = integrals(fi);
            save_ex(imgcachename, 'integral');
        end
    end
    
    if CACHE_FILE
        save_ex(cachename, 'integrals');
    end
end


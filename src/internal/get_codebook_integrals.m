function [ integrals ] = get_codebook_integrals(params, features, cluster_model)
%GET_CODEBOOKS Summary of this function goes here
%   Detailed explanation goes here

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

    scale_factor = max([0, min([1, params.integrals_scale_factor])]);
    cachename = sprintf('%s/%s-%s-%s-%d-%.3f.mat',...
                     basedir, params.class,...
                     type, params.stream_name, params.stream_max, scale_factor);

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename);
        if ~isfield(integrals, 'scale_factor')
            [integrals.scale_factor] = deal(1);
        end
        fprintf(1,'get_codebook_integrals: length of stream=%05d\n', length(features));
        return;
    end

    integrals = alloc_struct_array(length(features), 'I', 'curid', 'scale_factor');
    for fi=1:length(features)
        feature = features(fi);
        
        imgcachename = sprintf('%s/%s-%s-%d-%s-%.3f.mat',...
                               detaildir, params.class,...
                               feature.curid, feature.objectid, type, scale_factor);

        integral = integrals(fi);
        if CACHE_FILE && fileexists(imgcachename)
            load_ex(imgcachename);
            if ~isfield(integral, 'scale_factor')
                integral.scale_factor = 1;
            end
            integrals(fi) = integral;
            continue;
        end
        
        I = cluster_model.feature2codebookintegral(params, feature);
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
        integrals(fi).I = I;
        integrals(fi).curid = feature.curid;
        integrals(fi).scale_factor = scale_factor;
        
        
        if CACHE_FILE
            integral = integrals(fi);
            save_ex(imgcachename, 'integral');
        end
    end
    
    if CACHE_FILE
        save_ex(cachename, 'integrals');
    end
end


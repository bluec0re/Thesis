function svm_models = get_svms( params, query_codebooks, neg_codebooks )
%GET_SVMS Get trained exemplar svms from given codebooks
%
%   Syntax:     svm_models = get_svms( params, query_codebooks, neg_codebooks )
%
%   Input:
%       params - Configuration struct
%       query_codebooks - A codebook struct array. Required Fields: I, size, curid
%       neg_codebooks - Codebook struct array (Fields: I) or NxM matrix. N: Num codebooks, M: Codebook size
%
%   Output:
%       svm_models - Struct array of svm models. Fields: cb_size, codebook, curid, model

    profile_log(params);
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

    basedir = sprintf('%s/models/svms/', params.dataset.localdir);
    if CACHE_FILE == 1 && ~exist(basedir,'dir')
        mkdir(basedir);
    end

    src = 'raw';
    if params.query_from_integral
        src = 'integral';
    end
    cachename = sprintf('%s/%d-%d-%s-%s-%d-%d-%.3f-%s.mat',...
                     basedir, params.clusters, params.parts,...
                     params.class, params.stream_name, params.stream_max,...
                     params.codebook_scales_count, params.features_per_roi, src);

    if params.stream_max == 1
        cachename = strrep(cachename, '.mat', ['-' query_codebooks(1).curid '.mat']);
    end

    if ~isempty(query_codebooks.size)
        cachename = strrep(cachename, '.mat', sprintf('-%dx%d.mat', query_codebooks.size(1), query_codebooks.size(2)));
    end

    if CACHE_FILE && fileexists(cachename) && false % only save
        load_ex(cachename);
        svm_models = addHandlers(svm_models);
        fprintf(1,'get_svms: length of stream=%05d\n', length(svm_models));
        return;
    end

    if ~isfield(query_codebooks, 'I') || isempty(query_codebooks.I)
        svm_models = [];
        return;
    end

    if isstruct(neg_codebooks)
        neg_codebooks = horzcat(neg_codebooks.I);
    end

    if size(neg_codebooks, 1) < size(neg_codebooks, 2)
        neg_codebooks = neg_codebooks';clear NEG_CB
    end

    info('Using %d negative samples', size(neg_codebooks, 1));

    svm_models = alloc_struct_array(length(query_codebooks), 'model', 'curid', 'codebook', 'cb_size');
    wpos = params.esvm_default_params.train_positives_constant;
    for qi=1:length(query_codebooks)
        codebook = query_codebooks(qi);

        trainInstMatrix = double([codebook.I'; neg_codebooks]);
        trainLabelVector = double([ones([size(codebook.I, 2) 1]); zeros([size(neg_codebooks, 1) 1])]);

        m.cb_size = codebook.size;
        m.codebook = codebook.I;
        m.curid = codebook.curid;
        m.model = libsvmtrain(trainLabelVector, trainInstMatrix,...
                              sprintf('-s 0 -t 0 -c %f -w1 %.9f -q', params.esvm_default_params.train_svm_c, wpos));

        svm_models(qi) = m;
    end
    profile_log(params);

    if CACHE_FILE
        save_ex(cachename, 'svm_models');
    end
    svm_models = addHandlers(svm_models);
end

function svm_models = addHandlers(svm_models)
    for mi=1:length(svm_models)
        svm_models(mi).classify = @classify_codebooks;
    end
end

function scores = classify_codebooks(params, model, codebooks)
    profile_log(params);
    m = model.model;


    if params.use_libsvm_classification
        if size(codebooks, 1) == size(m.SVs, 2)
            codebooks = codebooks';
        end
        [~, ~, scores] = libsvmpredict(zeros([size(codebooks, 1) 1]), codebooks, m);
    else % produces NaNs
        weights = m.SVs' * m.sv_coef;

        if size(codebooks, 2) == size(weights, 1)
            scores = codebooks * weights - m.rho;
        else
            scores = codebooks' * weights - m.rho;
        end
        nans = isnan(scores);
        debg('%d NaNs produced!', sum(nans))
        scores(nans) = -999;
    end
    profile_log(params);
end

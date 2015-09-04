function [ svm_models ] = get_svms( params, query_codebooks, neg_codebooks )
%GET_SVMS Summary of this function goes here
%   Detailed explanation goes here

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

    basedir = sprintf('%s/models/svms/', params.dataset.localdir);
    if CACHE_FILE == 1 && ~exist(basedir,'dir')
        mkdir(basedir);
    end

    cachename = sprintf('%s/%d-%d-%s-%s-%d.mat',...
                     basedir, params.clusters, params.parts,...
                     params.class, params.stream_name, params.stream_max);

    if CACHE_FILE && fileexists(cachename)
        load_ex(cachename);
        svm_models = addHandlers(svm_models);
        fprintf(1,'get_svms: length of stream=%05d\n', length(svm_models));
        return;
    end
    
    if isstruct(neg_codebooks)
        neg_codebooks = horzcat(neg_codebooks.I);
    end
    
    if size(neg_codebooks, 1) < size(neg_codebooks, 2)
        neg_codebooks = neg_codebooks';
    end

    svm_models = alloc_struct_array(length(query_codebooks), 'model', 'curid', 'codebook', 'cb_size');
    wpos = params.esvm_default_params.train_positives_constant;
    for qi=1:length(query_codebooks)
        codebook = query_codebooks(qi);

        trainInstMatrix = [codebook.I'; neg_codebooks];
        trainLabelVector = [ones([size(codebook.I, 2) 1]); zeros([size(neg_codebooks, 1) 1])];
        
        m.cb_size = codebook.size;
        m.codebook = codebook.I;
        m.curid = codebook.curid;
        m.model = libsvmtrain(trainLabelVector, trainInstMatrix,...
                              sprintf('-s 0 -t 0 -c %f -w1 %.9f -q', params.esvm_default_params.train_svm_c, wpos));
        
        svm_models(qi) = m;
    end
    
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
    m = model.model;
    
% produces NaNs    
%     weights = m.SVs' * m.sv_coef;
%    
%     if size(codebooks, 2) == size(weights, 1)
%         scores = codebooks * weights - m.rho;
%     else
%         scores = codebooks' * weights - m.rho;
%     end
    if size(codebooks, 1) == size(m.SVs, 2)
        codebooks = codebooks';
    end
    [~, ~, scores] = libsvmpredict(zeros([size(codebooks, 1) 1]), codebooks, m);
end

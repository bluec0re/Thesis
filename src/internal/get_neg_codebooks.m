function neg_codebooks = get_neg_codebooks(params, cluster_model)
%GET_NEG_CODEBOOKS Load the negative codebooks for SVM training
%
%   Syntax:     neg_codebooks = get_neg_codebooks(params, cluster_model)
%
%   Input:
%       params        - Configuration
%       cluster_model - The model used to cluster features if no cache available
%
%   Output:
%       neg_codebooks - The negative calc_codebooks

    params.stream_name = 'query';
    params.feature_type = 'full-masked';
    neg_codebooks = get_codebooks(params, [], cluster_model);
    if ~isstruct(neg_codebooks)
        %setStatus('Collecting negative features...');
        neg_features = prepare_features(params);
        neg_codebooks = get_codebooks(params, neg_features, cluster_model);
        clear neg_features;
    end

    %setStatus('Concating codebooks...');
    neg_codebooks = horzcat(neg_codebooks.I);
end

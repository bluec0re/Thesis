function neg_codebooks = get_neg_codebooks(params, cluster_model)
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

function features = prepare_features(params, query_stream_set)

    if ~exist('query_stream_set', 'var')
        stream_params.stream_set_name = params.stream_name;
        stream_params.stream_max_ex = params.stream_max;
        stream_params.must_have_seg = 0;
        stream_params.must_have_seg_string = '';
        stream_params.model_type = 'exemplar';
        stream_params.cls = params.class;

        query_stream_set = esvm_get_pascal_stream_custom(stream_params, ...
                                              params.dataset);
    end

    features = filter_features(params, []);
    if isempty(features)
        features = whiten_features(params, []);
        if isempty(features)
            features = get_features_from_stream(params, query_stream_set);
            info('Whitening features...');
            features = whiten_features(params, features);
        end
        info('Filtering features...');
        features = filter_features(params, features);
    end
end
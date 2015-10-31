function database = load_database(params, cluster_model, roi_size)
    params.feature_type = 'full';
    params.stream_name = params.db_stream_name;
    params.class = '';
    database = get_codebook_integrals(params, [], cluster_model, roi_size);
    if ~isstruct(database)
        all_features = prepare_features(params);
        database = get_codebook_integrals(params, all_features, cluster_model, roi_size);
    end
end

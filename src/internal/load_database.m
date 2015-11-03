function database = load_database(params, cluster_model, roi_size)
%LOAD_DATABASE Loads the image database or generates it
%
%   Syntax:     database = load_database(params, cluster_model, roi_size)
%
%   Input:
%       params        - Configuration
%       cluster_model - The model to use for clustering
%       roi_size      - Size of the query part
%
%   Output:
%       database      - The loaded/generated database as struct array

    params.feature_type = 'full';
    params.stream_name = params.db_stream_name;
    params.class = '';
    database = get_codebook_integrals(params, [], cluster_model, roi_size);
    if ~isstruct(database)
        all_features = prepare_features(params);
        database = get_codebook_integrals(params, all_features, cluster_model, roi_size);
    end
end

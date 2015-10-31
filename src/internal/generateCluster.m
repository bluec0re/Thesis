function cluster_model = generateCluster(params)
%GENERATECLUSTER Generate a cluster model
%
%   Syntax:     cluster_model = generateCluster(params)
%
%   Input:
%       params - Configuration parameters
%
%   Output:
%       cluster_model - The model

    profile_log(params);
    params.feature_type = 'full';
    params.stream_name = params.db_stream_name;
    params.class = '';

    cluster_model = get_cluster(params, []);
    if ~isstruct(cluster_model)
        train_features = prepare_features(params);
        cluster_model = get_cluster(params, train_features);
    end
end

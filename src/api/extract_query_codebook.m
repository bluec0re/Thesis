function query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size )
%EXTRACT_QUERY_CODEBOOK extracts a query codebook based on the configuration
%
%   Syntax:     query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size )
%
%   Input:
%       params - Configuration struct
%       cluster_model - Model representing the current clustering method
%       query_file - Struct with information about the query file
%       roi_size - Bounding box of the query part
%
%   Output:
%       query_codebooks - the resulting codebook

    params.stream_max = 1;
    params.window_prefilter = false;
    params.inverse_search = false;

    bbox = query_file.bbox;
    if ~exist('roi_size', 'var')
        roi_size = bbox([3 4]) - bbox([1 2]) + 1;
    end

    if params.query_from_integral
        params.feature_type = 'full';
        params.class = '';
        query_feature.curid = query_file.curid;
        query_feature.I_size = [1 size(cluster_model.centroids, 1) size(query_file.I, 2) size(query_file.I, 1)];
        query_feature.objectid = 0;
        query_feature.bbs = query_file.bbox;
        query_feature.X = [];
        query_integrals = get_codebook_integrals(params, query_feature, cluster_model, roi_size);
        if ~isstruct(query_integrals)
            query_features = prepare_features(params, {query_file});
            query_integrals = get_codebook_integrals(params, query_features, cluster_model, roi_size);
            clear query_features;
        end
        [ query_codebooks.size, query_codebooks.I, ~ ] = calc_codebooks(params, query_integrals, bbox, params.parts );
        query_codebooks.I = query_codebooks.I';
        query_codebooks.curid = query_file.curid;
        query_codebooks.size = query_codebooks.size([3 4]) - query_codebooks.size([1 2]) + 1;
    else
        params.feature_type = 'bboxed';
        params.dataset.localdir = [];
        query_features = prepare_features(params, {query_file});
        query_codebooks = get_codebooks(params, query_features, cluster_model);
        clear query_features;
    end
end

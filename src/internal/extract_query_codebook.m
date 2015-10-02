function query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size )
%EXTRACT_QUERY_CODEBOOK Summary of this function goes here
%   Detailed explanation goes here

    params.stream_max = 1;

    bbox = query_file.bbox;
    if ~exist('roi_size', 'var')
        roi_size = bbox([3 4]) - bbox([1 2]) + 1;
    end

    if params.query_from_integral
        params.feature_type = 'full';
        query_integrals = get_codebook_integrals(params, [], cluster_model, roi_size);
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

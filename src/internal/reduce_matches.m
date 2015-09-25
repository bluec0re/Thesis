function [bbox, scores, idx] = reduce_matches(params, bbox, scores)
%REDUCE_MATCHES Reduces the amount of detected matches with a non-max suppression
%
%   Syntax:     [bbox, scores, idx] = reduce_matches(params, bbox, scores)
%
%   Input:
%       params - Configuration parameters
%       bbox - Nx4 matrix of bounding boxes [x, y, w, h]
%       scores - N dimensional vector of scores
%
%   Output:
%       bbox - New bounding boxes
%       scores - New scores
%       idx - Mapping between input and output (index vector)

    profile_log(params);
    if params.nonmax_type_min
        [bbox, scores, idx] = selectStrongestBbox(bbox, scores, 'RatioType', 'Min');
    else
        [bbox, scores, idx] = selectStrongestBbox(bbox, scores, 'RatioType', 'Union');
    end
end
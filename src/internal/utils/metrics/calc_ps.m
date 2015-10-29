function [ tps, fps, threshold ] = calc_ps( trueLabels, scores )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    p = inputParser;
    p.addRequired('trueLabels', @islogical);
    p.addRequired('scores', @isnumeric);
    parse(p, trueLabels, scores);
    trueLabels = p.Results.trueLabels;
    scores = p.Results.scores;

    if size(scores, 1) == size(trueLabels, 1)
        if size(scores, 2) ~= size(trueLabels, 2) || size(scores,1) > size(scores, 2)
            scores = scores';
            trueLabels = trueLabels';
        end
    elseif size(scores, 2) == size(trueLabels, 2)
    else
        error('dim mismatch');
    end

    [scores, idx] = sort(scores,'descend');
    trueLabels = trueLabels(idx);

    idx = find(diff(scores) ~= 0);
    idx = [idx(:); length(scores)];

    tps = cumsum(trueLabels);
    tps = tps(idx);
    tps = tps(:);
    fps = idx - tps(:);
    threshold = scores(idx);
    threshold = threshold(:);
end

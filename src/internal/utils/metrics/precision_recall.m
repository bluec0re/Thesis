function [ precision, recall, thresholds ] = precision_recall(trueLabels, scores, expected_relevant)
%PRECISION_RECALL Summary of this function goes here
%   Detailed explanation goes here

    [tps, fps, thresholds] = calc_ps(trueLabels, scores);

    if ~exist('expected_relevant', 'var') || isempty(expected_relevant)
        expected_relevant = tps(end);
    end

    precision = tps ./ (tps + fps);
    recall = tps ./ expected_relevant;

    last_idx = find(tps == tps(end));
    part = last_idx:-1:1;

    precision = [precision(part) 1];
    recall = [recall(part) 0];
    thresholds = thresholds(part);
end

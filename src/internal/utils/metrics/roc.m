function [ tpr, fpr, thresholds ] = roc( trueLabels, scores )
%ROC Summary of this function goes here
%   Detailed explanation goes here

    [tps, fps, thresholds] = calc_ps(trueLabels, scores);
    
    fpr = fps ./ fps(end);
    tpr = tps ./ tps(end);
end


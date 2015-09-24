function [ area ] = roc_auc( trueLabels, scores )
%ROC_AUC Summary of this function goes here
%   Detailed explanation goes here

    [tpr, fpr, ~] = roc(trueLabels, scores);
    
    area = auc(fpr, tpr, 'resort', true);
end


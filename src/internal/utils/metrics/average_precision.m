function ap = average_precision(trueLabels, scores, expected_relevant)
%AVERAGE_PRECISION Summary of this function goes here
%   Detailed explanation goes here

    if ~exist('expected_relevant', 'var')
        expected_relevant = [];
    end

    [precision, recall, ~] = precision_recall(trueLabels, scores, expected_relevant);

    ap = auc(recall, precision);
end

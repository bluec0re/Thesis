function [ truePositiveRate, falsePositiveRate ] = roc2 ( resultLabels, testLabels )
%ROC Summary of this function goes here
%   Detailed explanation goes here

    [ truePositiveRate, falsePositiveRate ] = roc(testLabels, resultLabels);
end


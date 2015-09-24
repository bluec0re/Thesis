function [ precision, recall ] = precisionRecall( resultLabels, testLabels )
%PRECISIONRECALL Summary of this function goes here
%   Detailed explanation goes here


    resultPositive = resultLabels == 1;
    resultNegative = resultLabels ~= 1;
    testPositive = testLabels == 1;
    testNegative = testLabels ~= 1;
    
    truePositive = sum(and(resultPositive, testPositive));
    trueNegative = sum(and(resultNegative, testNegative));
    falsePositive= sum(and(resultPositive, testNegative));
    falseNegative= sum(and(resultNegative, testPositive));
    
    precision = truePositive / (truePositive + falsePositive);
    recall = truePositive / (truePositive + falseNegative);
end


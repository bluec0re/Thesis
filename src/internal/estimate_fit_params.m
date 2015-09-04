function [ fit_params ] = estimate_fit_params( params, scores )
%ESTIMATE_FIT_PARAMS Summary of this function goes here
%   Detailed explanation goes here

    fit_params = sigmoid_fit(scores);
end


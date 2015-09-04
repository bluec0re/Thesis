function [ new_scores ] = adjust_scores( params, fit_params, scores )
%ADJUST_SCORES Summary of this function goes here
%   Detailed explanation goes here

    mu = fit_params(1);
    sigma = fit_params(2);
    mu = mu + 3 * sigma;
    new_scores = cdf('logistic', scores, mu, sigma) * 2 - 1;
end


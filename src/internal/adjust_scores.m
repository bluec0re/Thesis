function new_scores = adjust_scores( params, fit_params, scores )
%ADJUST_SCORES adjusts scores based on given gaussian fit parameters
%   Scores will applied on a gaussian curve. The curve is shifted by $3 * \sigma$
%   and the resulting scores rescaled by $new_scores * 2 - 1$
%
%   Syntax:     [ new_scores ] = adjust_scores( params, fit_params, scores )
%
%   Input:
%       params - Configuration parameters as struct
%       fit_params - 2D-Vector. [$\mu$, $\sigma$]
%       scores - Score vector to adjust
%
%   Output:
%       new_scores - Adjusted scores

    mu = fit_params(1);
    sigma = fit_params(2);
    mu = mu + 3 * sigma;
    new_scores = cdf('logistic', scores, mu, sigma) * 2 - 1;
end

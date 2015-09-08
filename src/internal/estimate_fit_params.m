function fit_params = estimate_fit_params( params, scores )
%ESTIMATE_FIT_PARAMS Estimates parameters of a gaussian curve
%   Can be used to adjust the scores
%
%   Syntax:     fit_params = estimate_fit_params( params, scores )
%
%   Input:
%       params - Configuration struct (currently not used)
%       scores - Score vector to fit to
%
%   Output:
%       fit_params - 2D-Vector of parameters [$\mu$, $\sigma$]

    fit_params = sigmoid_fit(scores);
    fit_params = fit_params([1 2]);
end

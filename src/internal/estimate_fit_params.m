function fit_params = estimate_fit_params( params, scores )

    fit_params = sigmoid_fit(scores);
    fit_params = fit_params([1 2]);
end


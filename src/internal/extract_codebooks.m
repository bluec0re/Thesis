function [bboxes, codebooks, images, windows, num_orig_windows] = extract_codebooks(params, svm_models, database, pos)
    sizes = {database.I_size};
    sizes = cell2mat(vertcat(sizes(:)));
    scale_factors = {database.scale_factor};
    scale_factors = cell2mat(vertcat(scale_factors(:)));
    max_w = max(sizes(:, 3) ./ scale_factors);
    max_h = max(sizes(:, 4) ./ scale_factors);

    roi_w = pos(3) - pos(1) + 1;
    roi_h = pos(4) - pos(2) + 1;
    windows = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
    num_orig_windows = size(windows, 1);
    [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, params.parts, svm_models);

    % expand bounding boxes by 1/2 of patch average
    if params.expand_bboxes && size(bboxes, 1) > 0
        patch_avg = ceil((max(vertcat(database.max_size)) + min(vertcat(database.min_size))) / 2 / 2);
        patch_avg = repmat(patch_avg, [size(bboxes, 1) 2]);
        patch_avg = patch_avg .* repmat([-1 -1 1 1], [size(bboxes, 1) 1]);
        bboxes = bboxes + patch_avg;
        bboxes(:, [1 3]) = max(1, min(bboxes(:, [1 3]), max_w));
        bboxes(:, [2 4]) = max(1, min(bboxes(:, [2 4]), max_h));
    end

    % required for libsvm
    codebooks = double(codebooks);
end

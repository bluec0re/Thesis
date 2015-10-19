function filtered_windows = filter_windows_by_inverse_search(params, integral, windows, svm_models)
    weight = svm_models.model.SVs' * svm_models.model.sv_coef;
    positive = mean(weight(weight > 0)) < weight & svm_models.codebook > 0;
    negative = mean(weight(weight < 0)) > weight & svm_models.codebook == 0;

    positive_any = get_any_match(params, integral, positive);
    positive_all = get_all_match(params, integral, positive);
    %negative_any = get_any_match(params, integral, negative);
    %negative_all = get_all_match(params, integral, negative);

    positive_any = adjust_mask(params, positive_any, integral, true);
    positive_all = adjust_mask(params, positive_all, integral, false);

    restricted = ~positive_all & positive_any;

    tlind = sub2ind(size(restricted), windows(:, 1), windows(:, 2));
    brind = sub2ind(size(restricted), windows(:, 3), windows(:, 4));

    filtered_windows = windows(restricted(tlind) & restricted(brind), :);
    debg('Removed %4d/%04d windows due to inverse search...', size(windows, 1)-size(filtered_windows, 1), size(windows, 1), false, false);
end

function image = get_any_match(params, integral, dimensions)
    if params.naiive_integral_backend
        filtered = integral.I(:, dimensions, :, :);
        image = squeeze(any(filtered, 2));
    elseif params.integral_backend_matlab_sparse
        filtered = integral.I(dimensions, :);
        image = squeeze(any(filtered, 1));
        image = reshape(image, integral.I_size(end-1:end));
    elseif params.use_kdtree
        filtered = integral.tree(dimensions);

        image = false(integral.I_size([end-1, end]));

        coords = [];
        for tree = filtered
            if isempty(tree.x)
                continue;
            end
            coords = [coords; [tree.x(:, 1) tree.y(tree.x(:, 2), 1)]];
        end
        coords = sortrows(coords);
        [x, i] = unique(coords(:, 1));
        y = repmat(1:size(image, 2), [length(x) 1]) >= repmat(coords(i, 2), [1, size(image, 2)]);
        map = false(integral.I_size([end-1, end]));
        map(x, :) = y;
        image(map) = true;
    elseif params.integral_backend_sum ||  params.integral_backend_overwrite
        filtered = integral.coords(ismember(integral.coords(:, 3), dimensions), 1:2);

        % sorts already
        [x, i] = unique(filtered(:, 1));
        y = filtered(i, 2);

        image = false(integral.I_size([end-1, end]));
        y = repmat(1:size(image, 2), [length(x) 1]) >= repmat(y, [1, size(image, 2)]);
        map = false(integral.I_size([end-1, end]));
        map(x, :) = y;
        image(map) = true;
    else
        [cb, x, y] = ind2sub(integral.I_size(end-2:end), integral.idx);
        i = find(ismember(cb, dimensions));
        x = x(i);
        y = y(i);

        [x, i] = sort(x);
        y = y(i);
        image = false(integral.I_size([end-1, end]));
        y = repmat(1:size(image, 2), [length(x) 1]) >= repmat(y, [1, size(image, 2)]);

        map = false(integral.I_size([end-1, end]));
        map(x, :) = y;
        image(map) = true;
    end
end

function image = get_all_match(params, integral, dimensions)
    if params.naiive_integral_backend
        filtered = integral.I(:, dimensions, :, :);
        image = squeeze(all(filtered, 2));
    elseif params.integral_backend_matlab_sparse
        filtered = integral.I(dimensions, :);
        image = squeeze(all(filtered, 1));
        image = reshape(image, integral.I_size(end-1:end));
    elseif params.use_kdtree
        filtered = integral.tree(dimensions);

        image = false([length(filtered) integral.I_size([end-1, end])]);

        j = 0;
        for tree = filtered
            if isempty(tree.x)
                continue;
            end
            j = j + 1;
            coords = [tree.x(:, 1) tree.y(tree.x(:, 2), 1)];
            [x, i, ci] = unique(coords(:, 1));
            y = repmat(1:size(image, 3), [length(x) 1]) >= repmat(coords(i, 2), [1, size(image, 3)]);
            map = false(integral.I_size([end-1, end]));
            map(x, :) = y;
            image(j, map) = true;
        end
        image = squeeze(all(image, 1));
    elseif params.integral_backend_sum ||  params.integral_backend_overwrite
        filtered = integral.coords(ismember(integral.coords(:, 3), dimensions), :);
        image = false([length(dimensions) integral.I_size([end-1, end])]);
        for j=1:length(dimensions)
            dim = dimensions(j);
            filtered2 = filtered(filtered(:, 3) == dim, 1:2);

            if isempty(filtered2)
                continue
            end

            % sorts already
            [x, i] = unique(filtered2(:, 1));
            y = filtered2(i, 2);
            %cb = filtered2(i, 3);

            y = repmat(1:size(image, 3), [length(x) 1]) >= repmat(y, [1, size(image, 3)]);
            map = false(integral.I_size([end-1, end]));
            map(x, :) = y;
            image(j, map) = true;
        end
        image = squeeze(all(image, 1));
    else
        [cb, x1, y1] = ind2sub(integral.I_size(end-2:end), integral.idx);
        i = find(ismember(cb, dimensions));
        x1 = x1(i);
        y1 = y1(i);

        image = false([length(dimensions) integral.I_size([end-1, end])]);
        for j=1:length(dimensions)
            dim = dimensions(j);
            i = cb == dim;
            x = x1(i);
            y = y1(i);

            % sorts already
            [x, i] = unique(x);
            y = y(i);
            %cb = filtered2(i, 3);

            y = repmat(1:size(image, 3), [size(coords, 1) 1]) >= repmat(coords(:, 2), [1, size(image, 3)]);
            map = false(integral.I_size([end-1, end]));
            map(x, :) = y;
            image(j, map) = true;
        end
        image = squeeze(all(image, 1));
    end
end

function new_mask = adjust_mask(params, mask, integral, left)
    if ~params.expand_bboxes
        new_mask = mask;
    end
    avg_patch = round(mean([integral.max_size; integral.min_size])/4);

    if left
        new_mask = circshift(mask, -avg_patch);
        new_mask(:, end-avg_patch(2)+1:end) = repmat(new_mask(:, end-avg_patch(2)), [1 avg_patch(2)]);
        new_mask(end-avg_patch(1)+1:end, :) = repmat(new_mask(end-avg_patch(1), :), [avg_patch(1) 1]);
    else
        new_mask = circshift(mask, avg_patch);
        new_mask(:, 1:avg_patch(2)) = repmat(new_mask(:, avg_patch(2)+1), [1 avg_patch(2)]);
        new_mask(1:avg_patch(1), :) = repmat(new_mask(avg_patch(1)+1, :), [avg_patch(1) 1]);
    end
end

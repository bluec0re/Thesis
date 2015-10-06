function codebook = sparse_codebook(integral, x, y)
%SPARSE_CODEBOOK Matlab implementation of the reconstruction of a kd-Tree integral image
%
%   Syntax:     codebook = sparse_codebook(integral, x, y)
%
%   Input:
%       integral - An integral image with kd-Tree storage backend
%       x, y     - Coordinate of requested codebook
%
%   Output:
%       codebook - the reconstructed codebook

    codebook = zeros([1 length(integral.tree)]);
    for ci=1:length(integral.tree)
        subtree = integral.tree(ci);
        if ~isempty(subtree.x) && ~isempty(subtree.y)
            data = kdtree_find_lower(subtree.x, x);
            if ~isempty(data)
                from = data(1);
                to = data(2);
                value = kdtree_find_lower(subtree.y(from:to, :), y);
                if ~isempty(value)
                    codebook(ci) = value;
                end
            end
        end
        % if ~isempty(subtree)
        %     ytree = kdtree_find_lower(subtree, x);
        %     value = kdtree_find_lower(ytree, y);
        %     codebook(ci) = value;
        % end
    end
end

function data = kdtree_find_lower(tree, value)
    upper = size(tree, 1);
    lower = 1;
    data = [];

    % prefail
    if tree(lower, 1) > value
        return;
    elseif tree(lower, 1) == value
        data = tree(lower, 2:end);
        return;
    elseif tree(upper, 1) <= value
        data = tree(upper, 2:end);
        return;
    end

    while upper > lower
        idx = round((upper+lower)/2);
        tv = tree(idx, 1);
        if tv == value
            data = tree(idx, 2:end);
            return;
        elseif tv > value
            upper = idx;
        else%if tv < value
            lower = idx;
        end

        if lower == upper - 1
            if tree(lower, 1) < value
                if value < tree(upper, 1)
                    data = tree(lower, 2:end);
                else
                    data = tree(upper, 2:end);
                end
            end
            return;
        end
    end
end

% function data = kdtree_find_lower(tree, value)
%     upper = length(tree);
%     lower = 1;
%     keyboard;
%     while upper ~= lower
%         idx = round(upper+lower)/2;
%         tv = tree(idx).value;
%         if tv == value
%             data = tree(idx).data;
%             return;
%         elseif tv > value
%             upper = idx;
%         elseif tv < value
%             lower = idx;
%         end
%
%         if lower == upper - 1 && tree(lower).value < value && value < tree(upper).value
%             data = tree(lower).data;
%             return;
%         end
%     end
% end

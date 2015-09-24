function area = auc(x, y, varargin)
    p = inputParser;
    addParameter(p, 'resort', false, @islogical);
    parse(p, varargin{:});
    
    direction = 1;
    
    y = reshape(y, [length(y) 1]);
    x = reshape(x, [length(x) 1]);
    
    if p.Results.resort
        [~, idx] = sortrows([y x], [1 2]);
        x = x(idx);
        y = y(idx);
    else
        dx = diff(x);
        if any(dx < 0)
            if all(dx <= 0)
                direction = -1;
            else
                error('x is not increasing');
            end
        end
    end
    
    area = direction * trapz(x, y);
end


function area = avg_precision( resultLabels, testLabels )
%AVG_PRECISION Summary of this function goes here
%   Detailed explanation goes here

    [ truePositiveRate, falsePositiveRate ] = roc2(resultLabels, testLabels);
    
    area = auc(falsePositiveRate, truePositiveRate);
end

function area = auc(x, y)

    direction = 1;
    dx = diff(x);
    
    if any(dx < 0)
        if all(dx <= 0)
            direction = -1;
        else
            error('x is not increasing');
        end
    end
    
    area = direction * trapz(y, x);
end

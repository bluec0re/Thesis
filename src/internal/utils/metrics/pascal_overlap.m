function [ overlapArea ] = pascal_overlap( groundTruth, prediction, varargin )
%PASCAL_RECTINT Summary of this function goes here
%   Detailed explanation goes here
    p = inputParser;
    addParameter(p, 'BoxTypeGT', 'Bounds')
    addParameter(p, 'BoxTypePR', 'Bounds')
    parse(p, varargin{:});

    x_g = groundTruth(1);
    y_g = groundTruth(2);

    if strcmp(p.Results.BoxTypeGT, 'Bounds')
        width_g = groundTruth(3) - groundTruth(1) + 1;
        height_g = groundTruth(4) - groundTruth(2) + 1;
    else
        width_g = groundTruth(3);
        height_g = groundTruth(4);
    end

    x_p = prediction(1);
    y_p = prediction(2);

    if strcmp(p.Results.BoxTypePR, 'Bounds')
        width_p = prediction(3) - prediction(1) + 1;
        height_p = prediction(4) - prediction(2) + 1;
    else
        width_p = prediction(3);
        height_p = prediction(4);
    end

    gt = [x_g, y_g, width_g, height_g];
    pr = [x_p, y_p, width_p, height_p];

    intersectionArea = rectint(gt, pr);
    unionCoords = [min(x_g, x_p), min(y_g, y_p), max(x_g + width_g - 1, x_p + width_p - 1), max(y_g + height_g - 1, y_p + height_p - 1)];
    unionArea = (unionCoords(3) - unionCoords(1) + 1) * (unionCoords(4) - unionCoords(2) + 1);
    overlapArea = intersectionArea/unionArea;
end

function [ xsteps, ysteps ] = getParts( minX, minY, maxX, maxY, NUM_PARTS)
%GETPARTS Summary of this function goes here
%   Detailed explanation goes here

    if NUM_PARTS == 4
        stepX = (maxX - minX) / 2;
        stepY = (maxY - minY) / 2;

        xsteps = [[0; stepX], [stepX; 2*stepX], [    0;   stepX], [stepX; 2*stepX]];
        ysteps = [[0; stepY], [    0;   stepY], [stepY; 2*stepY], [stepY; 2*stepY]];
        return;
    elseif NUM_PARTS == 1
        xsteps = [[0; maxX - minX]];
        ysteps = [[0; maxY - minY]];
        return;
    end

    splitX = floor(sqrt(NUM_PARTS));
    splitY = ceil(sqrt(NUM_PARTS));

    stepX = (maxX - minX) / splitX;
    stepY = (maxY - minY) / splitY;
    xsteps = cell2mat(arrayfun(@(x)([stepX * (x-1); stepX * x]), 1:splitX, 'UniformOutput', false));
    xsteps = repmat(xsteps, 1, splitY);
    ysteps = cell2mat(arrayfun(@(x)([stepY * floor((x-1)/splitX); stepY * ceil(x/splitX)]), 1:(splitY*splitX), 'UniformOutput', false));
end

function codebooks = getCodebooksFromIntegral(params, integralImg, bboxes, NUM_PARTS )
%GETCODEBOOKSFROMINTEGRAL Extract codebooks from a single integral image
%
%   Syntax:     codebooks = getCodebooksFromIntegral(params, integral_img, bboxes, num_parts)
%
%   Input:
%       params - Configuration struct
%       integral_img - SxNxWxH Matrix. S: scales, N: Codebook Size, W: Width, H: Height
%       bboxes - Mx4 Matrix of bounding boxes to extract
%       num_parts - (Even) number of segments to divide a single window into
%
%   Output:
%       codebooks - N2xSxM Matrix. N2: N*num_parts

    profile_log(params);
    % even slower??
    % not multiscale ready
    %codebooks = fast(integralImg, bboxes, NUM_PARTS);
    %return;

    if params.naiive_integral_backend
        %integralImg = reshape(integralImg.I, integralImg.I_size(2:end));
        integralImg = integralImg.I;

        iis = size(integralImg);
        if size(iis, 2) == 3
            features = iis(1);
            scales = 1;
            iis = [1 iis];
            integralImg = reshape(integralImg, iis);
        else
            scales = iis(1);
            features = iis(2);
        end
        codebooks = zeros([features * NUM_PARTS scales size(bboxes, 1)]);
        %secs = zeros([1 size(bboxes, 1)]);
        %parfor bid=1:size(bboxes, 1)
        for bid=1:size(bboxes, 1)
            tmp = tic;
            bb = bboxes(bid, :);
            xmin = bb(1);
            ymin = bb(2);
            xmax = bb(3);
            ymax = bb(4);
            [xsteps, ysteps] = getParts(xmin, ymin, xmax, ymax, NUM_PARTS);

            codebook = zeros([features, scales, NUM_PARTS]);
            % TODO: Bug -> make coords linear
    %         x1 = round(xmin + xsteps(1, :));
    %         x2 = round(xmin + xsteps(2, :));
    %         y1 = round(ymin + ysteps(1, :));
    %         y2 = round(ymin + ysteps(2, :));
    %         a = integralImg(:, x1, y1);
    %         b = integralImg(:, x2, y1);
    %         c = integralImg(:, x1, y2);
    %         d = integralImg(:, x2, y2);
    %         codebook = (a+d) - (b+c);

            %secs(bid) = toc(tmp);

            for si=1:scales
                for part=1:NUM_PARTS
                   x1 = round(xmin + xsteps(1, part));
                   x2 = round(xmin + xsteps(2, part));
                   y1 = round(ymin + ysteps(1, part));
                   y2 = round(ymin + ysteps(2, part));

                   %    A--B
                   %    |  |
                   %    C--D
                   a = integralImg(si, :, x1, y1);
                   b = integralImg(si, :, x2, y1);
                   c = integralImg(si, :, x1, y2);
                   d = integralImg(si, :, x2, y2);
                   codebook(:, si, part) = (a+d) - (b+c);
                end
            end
            codebooks(:, :, bid) = reshape(codebook, [features * NUM_PARTS scales 1]);
        end
    else

        iis = integralImg.I_size;
        if size(iis, 2) == 3 % never happens atm
            features = iis(1);
            scales = 1;
            iis = [1 iis];
            integralImg = reshape(integralImg, iis);
        else
            scales = iis(1);
            features = iis(2);
        end
        codebooks = zeros([features * NUM_PARTS scales size(bboxes, 1)]);
        %secs = zeros([1 size(bboxes, 1)]);
        parfor bid=1:size(bboxes, 1)
        %for bid=1:size(bboxes, 1)
            tmp = tic;
            bb = bboxes(bid, :);
            xmin = bb(1);
            ymin = bb(2);
            xmax = bb(3);
            ymax = bb(4);
            [xsteps, ysteps] = getParts(xmin, ymin, xmax, ymax, NUM_PARTS);

            codebook = zeros([features, scales, NUM_PARTS]);

            for si=1:scales
                for part=1:NUM_PARTS
                   x1 = uint32(round(xmin + xsteps(1, part)));
                   x2 = uint32(round(xmin + xsteps(2, part)));
                   y1 = uint32(round(ymin + ysteps(1, part)));
                   y2 = uint32(round(ymin + ysteps(2, part)));

                   %    A--B
                   %    |  |
                   %    C--D
                   %keyboard;
                   % sort order y x cb (3 2 1)
%                    tmp = integralImg.coords(:, 2) <= x1 & integralImg.coords(:, 3) <= y1;
%                    [dims, idx] = unique(integralImg.coords(tmp, 1), 'last', 'legacy');
%                    tmp = integralImg.scores(tmp);
%                    a = zeros([features, 1]);
%                    a(dims) = tmp(idx);
%
%
%                    tmp = integralImg.coords(:, 2) <= x2 & integralImg.coords(:, 3) <= y1;
%                    [dims, idx] = unique(integralImg.coords(tmp, 1), 'last', 'legacy');
%                    tmp = integralImg.scores(tmp);
%                    b = zeros([features, 1]);
%                    b(dims) = tmp(idx);
%
%                    tmp = integralImg.coords(:, 2) <= x1 & integralImg.coords(:, 3) <= y2;
%                    [dims, idx] = unique(integralImg.coords(tmp, 1), 'last', 'legacy');
%                    tmp = integralImg.scores(tmp);
%                    c = zeros([features, 1]);
%                    c(dims) = tmp(idx);
%
%                    tmp = integralImg.coords(:, 2) <= x2 & integralImg.coords(:, 3) <= y2;
%                    [dims, idx] = unique(integralImg.coords(tmp, 1), 'last', 'legacy');
%                    tmp = integralImg.scores(tmp);
%                    d = zeros([features, 1]);
%                    d(dims) = tmp(idx);
% old
%                    a = sparse_codebook(integralImg.coords, integralImg.scores, [x1 y1], features);
%                    b = sparse_codebook(integralImg.coords, integralImg.scores, [x2 y1], features);
%                    c = sparse_codebook(integralImg.coords, integralImg.scores, [x1 y2], features);
%                    d = sparse_codebook(integralImg.coords, integralImg.scores, [x2 y2], features);
                   a = sparse_codebook(integralImg, x1, y1);
                   b = sparse_codebook(integralImg, x2, y1);
                   c = sparse_codebook(integralImg, x1, y2);
                   d = sparse_codebook(integralImg, x2, y2);

                   codebook(:, si, part) = (a+d) - (b+c);
                   % very bad results??
                    % codebook(:, si, part) = sparse_codebook_integral(integralImg, [x1; x2], [y1; y2]);
                end
            end
            codebooks(:, :, bid) = reshape(codebook, [features * NUM_PARTS scales 1]);
        end
    end
    %mean(secs)
    profile_log(params);
end

% even slower??
function codebooks = fast(integralImg, bboxes, NUM_PARTS)
    iis = size(integralImg);
    deleteBox = bboxes(:, 1) > iis(2);
    deleteBox = deleteBox | bboxes(:, 2) > iis(3);
    bboxes(deleteBox, :) = [];
    bboxes(:, 3) = min(iis(2), bboxes(:, 3));
    bboxes(:, 4) = min(iis(3), bboxes(:, 4));

    codebooks = zeros([NUM_PARTS, iis(1), size(bboxes, 1)]);
    for part=1:NUM_PARTS
        partbboxes = round(bboxesForPart(bboxes, part, NUM_PARTS));
        a = sub2ind(iis(2:3), partbboxes(:, 1), partbboxes(:, 2));
        b = sub2ind(iis(2:3), partbboxes(:, 3), partbboxes(:, 2));
        c = sub2ind(iis(2:3), partbboxes(:, 1), partbboxes(:, 4));
        d = sub2ind(iis(2:3), partbboxes(:, 3), partbboxes(:, 4));

        a = integralImg(:, a);
        b = integralImg(:, b);
        c = integralImg(:, c);
        d = integralImg(:, d);

        codebooks(part, :, :) = (a+d) - (b+c);
    end

    codebooks = reshape(codebooks, [size(integralImg, 1) * NUM_PARTS, size(bboxes, 1)]);
end

function newbboxes = bboxesForPart(bboxes, part, NUM_PARTS)
    xparts = round(sqrt(NUM_PARTS));
    yparts = ceil(sqrt(NUM_PARTS));
    xsteps = (bboxes(:, 3) - bboxes(:, 1) + 1) / xparts;
    ysteps = (bboxes(:, 4) - bboxes(:, 2) + 1) / yparts;

    offsets = [xsteps * (mod(part - 1, xparts)), ysteps * floor((part - 1) / xparts)];

    newbboxes = bboxes;
    newbboxes(:, 1:2) = newbboxes(:, 1:2) + offsets;
    newbboxes(:, 3:4) = [xsteps, ysteps] + newbboxes(:, 1:2) - 1;
end

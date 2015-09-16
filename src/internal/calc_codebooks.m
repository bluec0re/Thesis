
function [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows_bb, NUM_PARTS )
%CALC_CODEBOOKS Extracts codebooks and bounding boxes from a given image database
%
%   Syntax:     [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows_bb, num_parts )
%
%   Input:
%       params - The configuration parameters, currently only required for profiling
%       database - The image database as struct array with the fields I, curid and optionally scale_factor
%       windows_bb - A Nx4 matrix of bounding boxes to to extract ($x_{min}$, $y_{min}$, $x_{max}$, $y_{max}$)
%       num_parts - (Even) number of segments a window should be divided to
%
%   Output:
%       bboxes - A Nx4 matrix of bounding boxes related to the extracted codebooks ($x_{min}$, $y_{min}$, $x_{max}$, $y_{max}$)
%       codebooks - A Nx(M*num_parts) matrix of M dimensional codebooks
%       images - A 1xN dimensional index vector for assigning codebooks to images

    profile_log(params);
    info('Calculating codebooks...');
    start = tic;

    [expectedCodebookCount, codebookSize] = expectedCodebooks(database, windows_bb, NUM_PARTS);

    % extract codebooks
    codebooks = zeros([expectedCodebookCount codebookSize]);
    bboxes = zeros([expectedCodebookCount 4]);
    images = zeros([expectedCodebookCount 1]);
    lastIdx = 1;
    for fi=1:length(database)
        filename = database(fi).curid;
        if isfield(database(fi), 'scale_factor')
            scale_factor = database(fi).scale_factor;
        else
            scale_factor = 1;
        end

        debg('-- [%4d/%04d] Calc codebooks for %s...', fi, length(database), filename, false);
        tmp = tic;
        s = size(database(fi).I);
        codebooksImg = reshape(database(fi).I, s(2:end));
        w = size(codebooksImg, 2);
        h = size(codebooksImg, 3);

        % adjust bounding boxes
        adjusted_windows_bb = windows_bb * scale_factor;

        imgWindowsBB = adjusted_windows_bb(adjusted_windows_bb(:, 1) < w & adjusted_windows_bb(:, 2) < h, :);
        imgWindowsBB(:, 3) = min(imgWindowsBB(:, 3), w);
        imgWindowsBB(:, 4) = min(imgWindowsBB(:, 4), h);


        % codebook x scales x amount
        codebooks3 = getCodebooksFromIntegral(params, codebooksImg, imgWindowsBB, NUM_PARTS);
        [cbdim, scales, cbnum] = size(codebooks3);
        % amount * scales x codebook
        codebooks2 = zeros([cbnum * scales, cbdim]);
        pos = 1;
        for si=1:scales
            codebooks2(pos:pos+cbnum-1, :) = reshape(codebooks3(:, si, :), [cbdim cbnum])';
            pos = pos + cbnum-1;
        end
        % amount * scales x 4
        % is sync with codebooks2??
        imgWindowsBB = repmat(imgWindowsBB, scales, 1);

        % is a codebook with 0 entries valid?
        valid_codebooks = any(codebooks2, 2);
        codebooks2(~valid_codebooks, :) = [];

        if isempty(codebooks2)
            err('No codebooks for %s?\n', filename);
            error('No codebooks for %s?\n', filename);
        end

        codebooks(lastIdx:lastIdx+size(codebooks2, 1)-1,:) = codebooks2;
        % readjust bounding boxes
        bboxes(lastIdx:lastIdx+size(codebooks2, 1)-1,:) = imgWindowsBB(valid_codebooks,:) / scale_factor;
        images(lastIdx:lastIdx+size(codebooks2, 1)-1) = ones([1 size(codebooks2, 1)]) * fi;
        lastIdx = lastIdx+size(codebooks2, 1);
        sec = toc(tmp);
        debg('DONE in %f sec', sec, false, true);
    end
    bboxes(images == 0, :) = [];
    codebooks(images == 0, :) = [];
    images(images == 0) = [];

    sec = toc(start);
    succ('DONE in %f sec', sec);
end

function [expectedCodebookCount, codebookSize] = expectedCodebooks(database, windows_bb, NUM_PARTS)
%EXPECTEDCODEBOOKS Tries to estimate the amount of codebooks extracted
%   Internally used to preallocate the memory for speed
%
%   Syntax:     [expectedCodebookCount, codebookSize] = expectedCodebooks(database, windows_bb, num_parts)
%
%   Input:
%       database - The image database as struct array with the field I
%       windows_bb - A Nx4 matrix of bounding boxes to to extract
%       num_parts - (Even) number of segments a window should be divided to
%
%   Output:
%       expectedCodebookCount - Estimated number of codebooks which will be extracted
%       codebookSize - Size of the resulting codebooks (M*num_parts)

    % calc expected codebook count
    expectedCodebookCount = 0;
    codebookSize = 0;
    for fi=1:length(database)
        codebooksImg = database(fi).I;
        w = size(codebooksImg, 3);
        h = size(codebooksImg, 4);
        wincnt = sum(windows_bb(:, 1) < w & windows_bb(:, 2) < h);
        expectedCodebookCount = expectedCodebookCount + wincnt;
        codebookSize = size(codebooksImg, 2) * NUM_PARTS;
    end
end

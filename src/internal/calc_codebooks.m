
function [ bboxes, codebooks, images ] = calc_codebooks(params, database, windows_bb, NUM_PARTS )

    profile_log(params);
    fprintf('Calculating codebooks...\n');
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

        fprintf('-- [%4d/%04d] Calc codebooks for %s...', fi, length(database), filename);
        tmp = tic;
        s = size(database(fi).I);
        codebooksImg = reshape(database(fi).I, s(2:end));
        w = size(codebooksImg, 2);
        h = size(codebooksImg, 3);
        imgWindowsBB = windows_bb(windows_bb(:, 1) < w & windows_bb(:, 2) < h, :);
        imgWindowsBB(:, 3) = min(imgWindowsBB(:, 3), w);
        imgWindowsBB(:, 4) = min(imgWindowsBB(:, 4), h);

        % adjust bounding boxes
        imgWindowsBB = imgWindowsBB * scale_factor;

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
            error('No codebooks for %s?\n', filename);
        end

        codebooks(lastIdx:lastIdx+size(codebooks2, 1)-1,:) = codebooks2;
        % readjust bounding boxes
        bboxes(lastIdx:lastIdx+size(codebooks2, 1)-1,:) = imgWindowsBB(valid_codebooks,:) / scale_factor;
        images(lastIdx:lastIdx+size(codebooks2, 1)-1) = ones([1 size(codebooks2, 1)]) * fi;
        lastIdx = lastIdx+size(codebooks2, 1);
        sec = toc(tmp);
        fprintf('DONE in %f sec\n', sec);
    end
    bboxes(images == 0, :) = [];
    codebooks(images == 0, :) = [];
    images(images == 0) = [];

    sec = toc(start);
    fprintf('DONE in %f sec\n', sec);
end

function [expectedCodebookCount, codebookSize] = expectedCodebooks(database, windows_bb, NUM_PARTS)
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

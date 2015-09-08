function [X, W, M, offsets, uus, vvs, scales] = getHogsInsideBox(t, I, mask, params)
%GETHOGSINSIDEBOX Restrict calculated HoGs to a given mask
%
%   Syntax:     [X, W, M, offsets, uus, vvs, scales] = getHogsInsideBox(t, I, mask, params)
%
%   Input:
%       t - Feature pyramid
%       I - Source image of features
%       mask - logical mask to restrict features (same size as source image)
%       params - Configuration parameters
%
%   Output:
%       X - Features (Nx775)
%       W - wavelet
%       M - Gradient
%       offsets - Patch offsets
%       uus - Patch positions
%       vvs - Patch positions
%       scales - Patch scales

    X = [];
    W = [];
    M = [];
    fsize  = params.esvm_default_params.init_params.features();
    S = [5 5];
    pyr_N = cellfun(@(x)prod([size(x,1) size(x,2)]-S+1),t.hog);
    % sumN = sum(pyr_N);
    % X = zeros(S(1)*S(2)*fsize,sumN);
    offsets = cell(length(t.hog), 1);
    uus = cell(length(t.hog),1);
    vvs = cell(length(t.hog),1);

    counter = 1;
    Igrad = imgradient(rgb2gray(I));
    for i = 1:length(t.hog)
        s = size(t.hog{i});
        NW = s(1)*s(2);
        ppp = reshape(1:NW,s(1),s(2));

        %delete elements of the borders (zero padding of ONE cell)
        if min(size(ppp)) >= 3
            ppp(:,1) = [];
            ppp(:,end) = [];
            ppp(1,:) = [];
            ppp(end,:) = [];

            newmask = imresize(mask, [s(1),s(2)]);
            newmask(:,1) = [];
            newmask(:,end) = [];
            newmask(1,:) = [];
            newmask(end,:) = [];
        else % mask is to small
            ppp = [];
            newmask = [];
        end

        IgradResized = imresize(Igrad, s(1:2)*16);
        IgradBlocks = mat2cell(IgradResized, ones(1, s(1))*16, ones(1, s(2))*16);
        meanGradBlocks = cellfun2(@(x)(mean(x(:))), IgradBlocks);
        curf_M = cat(2,meanGradBlocks{:})';

        %extract wavelet as well
        rI1 = rgb2gray(imresize(double(I)/255, s(1:2)*8));
        [cA,~,~,~] = dwt2(rI1,'db1');


        cell_pixelsA = mat2cell(cA, ones(1, s(1))*4, ones(1, s(2))*4);
        cell_pixelsA = cellfun(@(x)(x(:)),cell_pixelsA, 'UniformOutput', false);
        curf_A = cat(2,cell_pixelsA{:})';

        curf = reshape(t.hog{i},[],fsize);
        b = im2col(ppp,[S(1) S(2)]);

        %   newmask = imresize(mask, [s(1)-2,s(2)-2]);
        mb = im2col(newmask,[S(1) S(2)]);
        b(:,sum(mb,1) < prod(S)) = []; %If it's not totally covered by the box we discard it!

        offsets{i} = b(1,:);
        offsets{i}(end+1,:) = i;

        for j = 1:size(b,2)
            X(:,counter) = reshape (curf(b(:,j),:),[],1);
            W(:,counter) = reshape (curf_A(b(:,j),:),[],1);
            M(counter) = mean(curf_M(b(:,j)));
            counter = counter + 1;
        end

        [uus{i},vvs{i}] = ind2sub(s,offsets{i}(1,:));
    end
    offsets = cat(2,offsets{:});
    uus = cat(2,uus{:});
    vvs = cat(2,vvs{:});
    scales = t.scales;
end

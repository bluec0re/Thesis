function new = alpha_blend(A, B, alpha, mask)
%ALPHA_BLEND Blends 2 images together based on an alpha value
%            C = alpha * A + (1 - alpha) * B
%
%   Syntax:     C = alpha_blend(A, B, alpha[, mask])
%
%   Input:
%       A     - Image A (height, width[, colorchannels])
%       B     - Image B (height, width[, colorchannels])
%       alpha - Value between [0, 1]
%       mask  - Optional logical mask where blending should occur

    Asize = size(A);
    Bsize = size(B);

    if ~all(Asize(1:2) == Bsize(1:2))
        error('A and B must be same size');
    end

    if class(A) ~= class(B)
        error('A and B must be same type');
    end

    if length(Asize) < 3
        Asize = [Asize 1];
        A = reshape(A, Asize);
    end

    if length(Bsize) < 3
        Bsize = [Bsize 1];
        B = reshape(B, Bsize);
    end

    if Asize(3) > Bsize(3)
        B = repmat(B, [1 1 Asize(3) / Bsize(3)]);
        Bsize = size(B);
    end

    if ~exist('mask', 'var')
        mask = true(Bsize);
    end

    mask = mask(:);

    new = zeros(Asize, class(A));
    % blend each channel separatly
    for current_channel=1:Asize(3)
        channel = A(:, :, current_channel);
        Bchannel = B(:,:, current_channel);
        channel(mask) = channel(mask) * alpha + (1-alpha) * Bchannel(mask);
        new(:, :, current_channel) = channel;
    end
end

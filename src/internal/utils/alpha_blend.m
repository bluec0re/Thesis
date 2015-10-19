function new = alpha_blend(A, B, alpha, mask)
    Asize = size(A);
    Bsize = size(B);

    if ~all(Asize(1:2) == Bsize)
        error('A and B must be same size');
    end

    if class(A) ~= class(B)
        error('A and B must be same type');
    end

    if ~exist('mask', 'var')
        mask = true(Bsize);
    end

    mask = mask(:);

    new = zeros(Asize, class(A));
    for current_channel=1:Asize(3)
        channel = A(:, :, current_channel);
        channel(mask) = channel(mask) * alpha + (1-alpha) * B(mask);
        new(:, :, current_channel) = channel;
    end
end

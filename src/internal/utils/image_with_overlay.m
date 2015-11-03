function I2 = image_with_overlay(I, bbs)
%IMAGE_WITH_OVERLAY Draws a 40% transparent overlay to the image
%
%   Syntax:     I2 = image_with_overlay(I, bbs)
%
%   Input:
%       I   - Image to modify
%       bbs - Bounding box of area which shouldn't be overlayed
%
%   Output:
%       I2  - Overlayed image

    blend_mask = true([size(I, 1) size(I, 2)]);
    blend_mask(bbs(2):bbs(4), bbs(1):bbs(3)) = false;
    overlay = zeros([size(I, 1) size(I, 2)], 'uint8');
    I2 = alpha_blend(I, overlay, 0.4, blend_mask);
end

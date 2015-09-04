function [ I ] = get_image( params, name )
%GET_IMAGE Summary of this function goes here
%   Detailed explanation goes here

    filename = sprintf(params.dataset.imgpath, name);
    I = imread(filename);
end


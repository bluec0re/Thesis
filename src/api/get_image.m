function I = get_image( params, name )
%GET_IMAGE Loads a pascal image by its name
%
%   Syntax:     I = get_image( params, name )
%
%   Input:
%       params - Configuration struct
%       name - The image name
%
%   Output:
%       I - The loaded image

    filename = sprintf(params.dataset.imgpath, name);
    I = imread(filename);
end

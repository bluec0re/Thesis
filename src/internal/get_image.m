function I = get_image( params, name )

    filename = sprintf(params.dataset.imgpath, name);
    I = imread(filename);
end


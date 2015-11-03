function codebook = codebook_for_image_part( curid, varargin )
%CODEBOOK_FOR_IMAGE_PART Testfunction to load a codebook from a integral image part

    params = get_default_configuration;
    keywords = parse_keywords(varargin, fieldnames(params));
    params = merge_structs(params, keywords);
    params.stream_max = 1;

    rec = PASreadrecord(sprintf(params.dataset.annopath, curid));
    for obj = rec.objects
        if strcmp(obj.class, params.class)
            roi = obj.bbox;
            roi_size = roi([3 4]) - roi([1 2]) + 1;
            break;
        end
    end

    files = get_possible_cache_files(['results/models/codebooks/integral/images/' params.class '-' curid '*' num2str(params.codebook_scales_count) '-*x*.mat']);
    res = regexp(files{1}, '\d+x', 'match');
    res = strrep(res{1}, 'x', '');
    format = strrep(strrep(files{1}, [res 'x'], '%dx'), ['x' res], 'x%d');
    [files, sizes] = sort_cache_files(files, format);

    cachename = filter_cache_files(params, files, sizes, roi_size);
    integral = load_ex(cachename);
    integral = integral.integral;

    [ bbox, codebook, ~ ] = calc_codebooks(params, integral, roi, params.parts );
    keyboard;
end

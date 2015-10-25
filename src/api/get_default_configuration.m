function params = get_default_configuration()
%GET_DEFAULT_CONFIGURATION returns a default configuration
%
%   Syntax:     params = get_default_configuration()
%
%   Output:
%       params - The default configuration

    dataset_directory = 'VOC2011';
    data_directory = 'DBs/Pascal/';
    results_directory = 'results';

    params = struct;
    params.class = 'bicycle';
    params.parts = 4;
    params.clusters = 1000;
    %params.integrals_scale_factor = 0.75; % save only 3 of 4 entries
    params.integrals_scale_factor = 1;
    params.stream_max = 100; % default database contains only 50 images, but multiple objects per image
    params.stream_name = 'query';
    params.codebook_type = 'double';
    params.codebook_scales_count = 3;
    params.nonmax_type_min = true;
    params.use_calibration = true;
    params.features_per_roi = 2;
    params.query_from_integral = false;
    params.default_query_file = '2008_000615';
    params.default_query_file = '2008_001566';
    params.default_query_file = '2008_004363';
    params.default_bounding_box = [];
    params.use_libsvm_classification = true;
    params.expand_bboxes = true;
    params.naiive_integral_backend = true;
    params.window_margin = 10; % pixels
    params.max_window_scales = 10;
    params.min_window_size = 0.5; % clip no more than percentage
    params.use_kdtree = false;
    params.integral_backend_overwrite = false;
    params.integral_backend_sum = false;
    params.integral_backend_matlab_sparse = false;
    params.precalced_windows = false;
    params.inverse_search = false;
    params.memory_cache = true;
    params.use_threading = true;
    params.window_prefilter = false;

    params.esvm_default_params = esvm_get_default_params;
    params.esvm_default_params.detect_pyramid_padding = 0;
    params.esvm_default_params.detect_add_flip = 0;


    params.dataset = esvm_get_voc_dataset(dataset_directory,...
                                          data_directory,...
                                          results_directory);

    % custom image sets
    params.dataset.clsimgsetpath = 'data/%s_%s.txt';
    params.dataset.imgsetpath = 'data/%s.txt';

    params.default_bounding_box = get_bounding_box(params);
    params.get_bounding_box = @get_bounding_box;
end

function bbox = get_bounding_box(params)
    try
        rec = PASreadrecord(sprintf(params.dataset.annopath, params.default_query_file));
        for obj = rec.objects
            if strcmp(obj.class, params.class)
                initbb = obj.bbox;
                bbox = [initbb(1:2), initbb(3:4) - initbb(1:2) + 1];
                break;
            end
        end
    catch
    end
end

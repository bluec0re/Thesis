function [ results ] = measure_speeds( func, num_images )
%MEASURE_SPEEDS Summary of this function goes here
%   Detailed explanation goes here

    dataset_directory = 'VOC2011';
    data_directory = 'DBs/Pascal/';
    results_directory = 'results';

    params = struct;
    params.class = 'bicycle';
    params.parts = 4;
    params.clusters = 1000;
    params.stream_max = num_images;
    params.esvm_default_params = esvm_get_default_params;
    params.esvm_default_params.detect_pyramid_padding = 0;
    params.esvm_default_params.detect_add_flip = 0;


    params.dataset = esvm_get_voc_dataset(dataset_directory,...
                                          data_directory,...
                                          results_directory);

    results = func(params);
end

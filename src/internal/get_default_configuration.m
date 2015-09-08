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
    params.integrals_scale_factor = 0.75; % save only 3 of 4 entries
    params.stream_max = 100;
    params.codebook_type = 'double';
    
    params.esvm_default_params = esvm_get_default_params;
    params.esvm_default_params.detect_pyramid_padding = 0;
    params.esvm_default_params.detect_add_flip = 0;


    params.dataset = esvm_get_voc_dataset(dataset_directory,...
                                          data_directory,...
                                          results_directory);
end


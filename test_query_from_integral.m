addpath(genpath('src'));
addpath(genpath('vendors'));

params = get_default_configuration;
params.default_query_file = '2008_001566';
params.naiive_integral_backend = false;
params.parts = 1;
params.codebook_scales_count = 1;
I = get_image(params, params.default_query_file);
params.default_bounding_box = params.get_bounding_box(params);
%params.default_bounding_box([1 2]) = [1 1];
params.default_bounding_box([1 2]) = [size(I, 2) size(I, 1)] - params.default_bounding_box([3 4]);
%params.codebook_scales_count = 1;
%params.features_per_roi = 1;

log_file('/dev/null');
set_log_level('debug');
query_file.I = I;
pos = params.default_bounding_box;
curid = params.default_query_file;
params.class = '';
query_file.bbox = pos;
query_file.bbox([3 4]) = pos([3 4]) + pos([1 2]) + 1;
query_file.cls = 'unknown';
query_file.objectid = 1;
query_file.curid = curid;

I(query_file.bbox([2 4]), query_file.bbox(1):query_file.bbox(3), 1) = 255;
I(query_file.bbox([2 4]), query_file.bbox(1):query_file.bbox(3), [2 3]) = 0;
I(query_file.bbox(2):query_file.bbox(4), query_file.bbox([1 3]), 1) = 255;
I(query_file.bbox(2):query_file.bbox(4), query_file.bbox([1 3]), [2 3]) = 0;

close all;
imshow(I);

clusterparams = params;
clusterparams.feature_type = 'full';
clusterparams.stream_name = 'database';
clusterparams.class = '';

cluster_model = get_cluster(clusterparams, []);

if evalin('base', 'exist(''NEG_MODEL'', ''var'');')
    debg('++ Using preloaded negative model');
    params.neg_model = evalin('base', 'NEG_MODEL;');
else
    params.neg_model = get_full_neg_model();
    assignin('base', 'NEG_MODEL', params.neg_model);
end

params.query_from_integral = true;
integral_codebook = extract_query_codebook(params, cluster_model, query_file);

params.query_from_integral = false;
raw_codebook = extract_query_codebook(params, cluster_model, query_file);

figure;
bar(integral_codebook.I);
title('Integral');

figure;
bar(raw_codebook.I);
title('Raw');


diff = raw_codebook.I - integral_codebook.I;

figure;
bar(diff);
title('Diff: Raw - Integral');

raw = double(raw_codebook.I > 0);
figure;
bar(raw);
title('Raw non null');


integral = double(integral_codebook.I > 0);
figure;
bar(integral);
title('Integral non null');


diff = raw - integral;

figure;
bar(diff);
title('Diff: Raw - Integral non null');

figure;
bar(double(diff == 0 & raw ~= 0 & integral ~= 0));
title('Common: non null');

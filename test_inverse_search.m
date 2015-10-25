addpath(genpath('src'));
addpath(genpath('vendors'));

params = get_default_configuration;
params.parts = 1;
params.clusters = 512;
%params.query_from_integral = true;

log_file('/dev/null');
old_params = params;

params.feature_type = 'full';
params.stream_name = 'database';
params.class = '';
cluster_model = get_cluster(params, []);
params = old_params;

params.stream_name = 'query';
params.feature_type = 'full-masked';
neg_codebooks = get_codebooks(params, [], cluster_model);
if ~isstruct(neg_codebooks)
    %setStatus('Collecting negative features...');
    neg_features = prepare_features(params);
    neg_codebooks = get_codebooks(params, neg_features, cluster_model);
    clear neg_features;
end

%setStatus('Concating codebooks...');
neg_codebooks = horzcat(neg_codebooks.I);
params = old_params;

pos = params.default_bounding_box;
roi_size = pos([3 4]);
pos([3 4]) = pos([3 4]) + pos([1 2]) - 1;

%%
query_file.I = get_image(params, params.default_query_file);
query_file.bbox = pos;
query_file.cls = 'unknown';
query_file.objectid = 1;
query_file.curid = params.default_query_file;

params.stream_max = 1;
if params.query_from_integral
    params.feature_type = 'full';
else
    params.feature_type = 'bboxed';
    params.dataset.localdir = [];
end

if evalin('base', 'exist(''NEG_MODEL'', ''var'');')
    debg('++ Using preloaded negative model');
    params.neg_model = evalin('base', 'NEG_MODEL;');
else
    params.neg_model = get_full_neg_model();
    assignin('base', 'NEG_MODEL', params.neg_model);
end

params.dataset.localdir = old_params.dataset.localdir;
query_codebooks.size = roi_size;
query_codebooks.curid = params.default_query_file;
svm_models = [];%get_svms(params, query_codebooks, neg_codebooks);
if ~isstruct(svm_models)
    if ~params.query_from_integral
        params.dataset.localdir = [];
    end
    query_codebooks = extract_query_codebook( params, cluster_model, query_file, roi_size );
    debg('Got %d codebooks', length(query_codebooks));

    params.dataset.localdir = [];%old_params.dataset.localdir;
    svm_models = get_svms(params, query_codebooks, neg_codebooks);
end
params = old_params;


weight = svm_models.model.SVs' * svm_models.model.sv_coef;
files = {
'2008_004363',...
'2008_000562',...
'2009_004882',...
'2010_003701',...
'2010_002814',...
'2010_000342',...
'2009_004364',...
'2010_005951',...
'2011_001726'
}
%'2008_002098',...
if exist('results/reverse_search', 'dir')
    rmdir('results/reverse_search', 's');
end
mkdir('results/reverse_search');
%for fi=1:length(files)
%    imid = files{fi};
%    load_ex(['results/models/codebooks/integral/naiive/images/512--' imid '-0-full-1.000-double-3-211x211.mat']);
if ~exist('integrals', 'var')
    load_ex(['results/models/codebooks/integral/naiive/512--full-database-100-1.000-double-3-211x211.mat']);
end
for ii=1:length(integrals)
    integral = integrals(ii);
    imid = integral.curid;
    I = squeeze(integral.I);
    avg_patch = round(mean([integral.max_size; integral.min_size])/4)
    foo = mean(weight(weight>0)) < weight & svm_models.codebook > 0;
    negative = mean(weight(weight < 0)) > weight & svm_models.codebook == 0;
    sum(foo)
    sum(negative)
    I2 = I(foo, :, :);
    I3 = squeeze(sum(I2, 1));
    I4 = squeeze(all(I2, 1));
    I5 = squeeze(any(I2, 1));
    I6 = I3<sum(foo)/3;
    In = I(negative, :, :);
    In3 = squeeze(sum(In, 1));
    In4 = squeeze(all(In, 1));
    In5 = squeeze(any(In, 1));

    I5 = circshift(I5, -avg_patch);
    I5(:, end-avg_patch(2)+1:end) = repmat(I5(:, end-avg_patch(2)), [1 avg_patch(2)]);
    I5(end-avg_patch(1)+1:end, :) = repmat(I5(end-avg_patch(1), :), [avg_patch(1) 1]);
    I4 = circshift(I4, avg_patch);
    I4(:, 1:avg_patch(2)) = repmat(I4(:, avg_patch(2)+1), [1 avg_patch(2)]);
    I4(1:avg_patch(1), :) = repmat(I4(avg_patch(1)+1, :), [avg_patch(1) 1]);

    img = get_image(params, imid);
    mask = (~I5 | I6 | I4)';
    mask = (~I5 | I4)';
    s = size(img);
    blend1 = alpha_blend(zeros(s(1:2), class(img)), ones(s(1:2), class(img))*255, 0, I4');
    blend2 = alpha_blend(zeros(s(1:2), class(img)), ones(s(1:2), class(img))*255, 0, ~I5');
    blend = zeros(s, class(img));
    blend(:, :, 1) = blend1;
    blend(:, :, 2) = blend2;
    img2 = alpha_blend(img, blend, 0.4, mask);
    imwrite(img2, sprintf('results/reverse_search/%s-%s.jpg', params.default_query_file, imid));
    continue;

    figure(ii);
    x = In3;% - In3;
    min(x(:))
    max(x(:))
    %x = uint8(x / max(x(:)) * 255)';
    x = uint8(x / (max(x(:)) - min(x(:))))';
    img_1 = squeeze(img(:, :, 1));
    img_1 = (1-x) .* x  + x .* img_1;
    %img_1 = x .* img_1;
    img_2 = squeeze(img(:, :, 2));
    %img_2 = x .* img_2;
    img_3 = squeeze(img(:, :, 3));
    %img_3 = x .* img_3;
    img_1 = reshape(img_1, [s(1:2) 1]);
    img_2 = reshape(img_2, [s(1:2) 1]);
    img_3 = reshape(img_3, [s(1:2) 1]);
    img2 = cat(3, img_1, img_2, img_3);
    imshow(img2);
end

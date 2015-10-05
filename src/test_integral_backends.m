%parpool;
params = get_default_configuration;
pos = params.default_bounding_box;

if exist('integral_backend.log', 'file')
    delete('integral_backend.log');
end
log_file('integral_backend.log');
set_log_level('debug');

if ~exist('numclusters', 'var')
    numclusters = 512;
end


if ~exist('database', 'var')
    load_ex(['results/models/codebooks/integral/naiive/' num2str(numclusters) '--full-database-100-1.000-double-3-86x86.mat']);
    %load_ex(['results/models/codebooks/integral/naiive/images/' num2str(numclusters) '--2007_008932-0-full-1.000-double-3-86x86.mat']);
    if ~exist('integrals', 'var') && exist('integral', 'var')
        integrals = integral;
        clear integral;
    end
    params.naiive_integral_backend = true;
    if ~isfield(integrals, 'I_size')
        sizes = cellfun(@size, {integrals.I}, 'UniformOutput', false);
        [integrals.I_size] = deal(sizes{:});
    end
    database = integrals;
    clear integrals;
end
params.naiive_integral_backend = true;

sizes = {database.I_size};
sizes = cell2mat(vertcat(sizes(:)));
scale_factors = {database.scale_factor};
scale_factors = cell2mat(vertcat(scale_factors(:)));
max_w = max(sizes(:, 3) ./ scale_factors)
max_h = max(sizes(:, 4) ./ scale_factors)

roi_w = pos(3);
roi_h = pos(4);
windows = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
[ bboxes, codebooks, images ] = calc_codebooks(params, database, windows, params.parts );

%%
if ~exist('database2', 'var')
    load_ex(['results/models/codebooks/integral/sparse-kd/' num2str(numclusters) '--full-database-100-1.000-double-3-86x86.mat']);
    %load_ex(['results/models/codebooks/integral/sparse/images/' num2str(numclusters) '--2007_008932-0-full-1.000-double-3-86x86.mat']);
    if ~exist('integrals', 'var') && exist('integral', 'var')
        integrals = integral;
        clear integral;
    end
    if ~isfield(integrals, 'I_size')
        sizes = cellfun(@size, {integrals.I}, 'UniformOutput', false);
        [integrals.I_size] = deal(sizes{:});
    end
    database2 = integrals;
    clear integrals;
end
params.naiive_integral_backend = false;
params.use_kdtree = true;
params.integral_backend_overwrite = false;
params.integral_backend_sum = false;
params.integral_backend_matlab_sparse = false;

sizes = {database2.I_size};
sizes = cell2mat(vertcat(sizes(:)));
scale_factors = {database2.scale_factor};
scale_factors = cell2mat(vertcat(scale_factors(:)));
max_w = max(sizes(:, 3) ./ scale_factors);
max_h = max(sizes(:, 4) ./ scale_factors);

roi_w = pos(3);
roi_h = pos(4);
windows2 = calc_windows(params, max_w, max_h, roi_w  * 0.75, roi_h * 0.75);
[ bboxes2, codebooks2, images2 ] = calc_codebooks(params, database2, windows2, params.parts );

same = codebooks2 == codebooks;

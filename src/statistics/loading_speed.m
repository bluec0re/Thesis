function [ results ] = loading_speed(params)
%LOADING_SPEED Measures speed differnces between serialize and unserialized data

    basedir = sprintf('%s/models/codebooks/integral/', params.dataset.localdir);

    results.num_images = params.stream_max;

    % serialized
    results.serialized = serialized(params, basedir, params.stream_max);

    % unserialized
    results.raw = raw(params, basedir, params.stream_max);
end

function result = serialized(params, basedir, num_images)
    result = struct;
    fname = sprintf('%s/%s-%s-%s-%d-%.3f.mat', basedir,...
        params.class, params.feature_type, params.stream_name, num_images, ...
        params.integrals_scale_factor);

    if ~exist(fname, 'file')
        return
    end

    result.filename = fname;
    stat = dir(fname);
    result.fsize = stat.bytes;
    tmp = tic;
    load(fname);
    result.load_time = toc(tmp);
    tmp2 = tic;
    integrals = hlp_deserialize(integrals);
    result.deserial_time = toc(tmp2);
    result.total_time = toc(tmp);
    stat = whos('integrals');
    result.var_size = stat.bytes;
end

function result = raw(params, basedir, num_images)
    result = struct;
    fname = sprintf('%s/%s-%s-%s-%d-%.3f_unser.mat', basedir,...
        params.class, params.feature_type, params.stream_name, num_images, ...
        params.integrals_scale_factor);

    if ~exist(fname, 'file')
        return
    end

    result.filename = fname;
    stat = dir(fname);
    result.fsize = stat.bytes;
    tmp = tic;
    load(fname);
    result.load_time = toc(tmp);
    result.total_time = toc(tmp);
    stat = whos('integrals');
    result.var_size = stat.bytes;
end

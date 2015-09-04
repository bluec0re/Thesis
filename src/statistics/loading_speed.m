function [ results ] = loading_speed(params)
%LOADING_SPEED Summary of this function goes here
%   Detailed explanation goes here
    basedir = sprintf('%s/models/codebooks/integral/', params.dataset.localdir);
    
    results.num_images = params.stream_max;
    
    % serialized
    results.serialized = serialized(basedir, params.stream_max);
    
    % unserialized
    results.raw = raw(basedir, params.stream_max);
end

function result = serialized(basedir, num_images)
    result = struct;
    fname = sprintf('%s/bicycle-full-train-%d.mat', basedir, num_images);
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

function result = raw(basedir, num_images)
    result = struct;
    fname = sprintf('%s/bicycle-full-train-%d_unser.mat', basedir, num_images);
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
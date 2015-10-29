function measure_results(varargin)
%MEASURE_RESULTS Summary of this function goes here
%   Detailed explanation goes here

    params = get_default_configuration;
    params.force_remeasure = false;
    params.force_recollect = false;
    keywords = parse_keywords(varargin, fieldnames(params));
    params = merge_structs(params, keywords);
    %log_file('measure_results.log');
    log_file('/dev/null');
    log_level('debug');

    srcdir = [params.dataset.localdir filesep 'queries' filesep 'scaled'];

    if params.force_remeasure || params.force_recollect || ~exist([srcdir filesep 'measure.mat'], 'file')
        groundTruth = load_groundtruth(params);
        measureExemplar(params, groundTruth);
        measures = measureMy(params, groundTruth);
    else
        load_ex([srcdir filesep 'measure.mat']);
    end
    performance_matrix(params, measures, 'imageap');
    performance_matrix(params, measures, 'bboxap');
end

function performance_matrix(params, measures, apfield)
    queries = cellfun(@(x)x{1}, {measures.curid}, 'UniformOutput', false);
    uqueries = unique(queries);
    for qi=1:length(uqueries)
        curid = uqueries{qi};
        srcdir = [params.dataset.localdir filesep 'queries' filesep 'scaled' filesep 'perf-' apfield filesep curid];
        if exist(srcdir, 'dir')
            rmdir(srcdir, 's');
        end
        mkdir(srcdir);
        submeasures = measures(strcmp(queries, curid));
        group = [submeasures.group];
        backends = {group.backend};
        clusters = [group.cluster];
        integral_scales = [group.integral_scale];
        codebook_types = {group.codebook_type};
        paths = {group.rest};
        scorings = {group.scoring};

        upaths = unique(paths);
        ubackends = unique(backends);
        uclusters = unique(clusters);
        uintegral_scales = unique(integral_scales);
        ucodebook_types = unique(codebook_types);
        uscorings = unique(scorings);

        f = fopen([srcdir filesep 'performance_rest.csv'], 'w');
        fprintf(f, 'path amount min mean max\n');
        for pi=1:length(upaths)
            path = upaths{pi};

            idx = strcmp(paths, path);
            aps = [submeasures(idx).(apfield)];
            fprintf(f, '%s %d %f %f %f\n', path, length(aps), min(aps), mean(aps), max(aps));
        end
        fclose(f);
        %restrict_to = '3-NumScales/nonmax-union/calibrated/2-featPerRoi/querysrc-raw/nonexpanded-bbs/2008_001566';

        for pi=1:length(upaths)
            performance_matrix = zeros([length(uscorings) length(ubackends) length(uclusters) length(uintegral_scales) length(ucodebook_types)]);
            restrict_to = upaths{pi};
            debg('[%4d/%04d] Processing %s', pi, length(upaths), restrict_to);
            for s=1:length(uscorings)
                scoring = uscorings(s);
                for b=1:length(ubackends)
                    backend = ubackends(b);
                    for c=1:length(uclusters)
                        cluster = uclusters(c);
                        for is=1:length(uintegral_scales)
                            integral_scale = uintegral_scales(is);
                            for ct=1:length(ucodebook_types)
                                codebook_type = ucodebook_types(ct);

                                idx = strcmp(scorings, scoring) &...
                                      strcmp(backends, backend) &...
                                      clusters == cluster &...
                                      integral_scales == integral_scale &...
                                      strcmp(codebook_types, codebook_type);
                                idx = idx & strcmp(paths, restrict_to);

                                if any(idx)
                                    %performance_matrix(b, c, is, ct) = mean([submeasures(idx).(apfield)]);
                                    performance_matrix(s, b, c, is, ct) = [submeasures(idx).(apfield)];
                                    %performance_matrix{b, c, is, ct} = [submeasures(idx).(apfield)];
                                end
                            end
                        end
                    end
                end
            end
            close all;

            for s=1:length(uscorings)
                scoring = uscorings{s};
                aps = [];
                for ct=1:length(ucodebook_types)
                    for b=1:length(ubackends)
                        for c=1:length(uclusters)
                            for is=1:length(uintegral_scales)
                                aps = [aps performance_matrix(s, b, c, is, ct)];
                            end
                        end
                    end
                end
                aps(isnan(aps)) = 0;


                f= figure('PaperUnits', 'normalized', 'PaperPosition', [0 0 1 0.8], 'Visible', 'Off');
                steps = size(aps, 2) / length(uintegral_scales);
                colors = {'red', 'blue', 'green'};
                for is=1:length(uintegral_scales)
                    idx = is:length(uintegral_scales):size(aps, 2);
                    tmp = zeros([1 size(aps, 2)]);
                    tmp(idx) = aps(idx);
                    h = bar(tmp, colors{is});
                    if is == 1
                        hold on;
                    end
                end
                hold off;
                ylim([0 1]);
                %xlim([0 size(aps, 2)+1]);
                %scale_axis = gca;
                cluster_axis = gca;
                sqz = 0.03;
                %set(scale_axis, 'Position', get(scale_axis, 'Position') + [0 sqz 0 -sqz ]);
                %cluster_axis = axes('Position', get(scale_axis, 'Position') .* [1 1 1 0.001] - [0 sqz 0 0],'Color','none');
                set(cluster_axis, 'Position', get(cluster_axis, 'Position') + [0 sqz 0 -sqz]);
                backend_axis = axes('Position', get(cluster_axis, 'Position') .* [1 1 1 0.001] - [0 sqz 0 0],'Color','none');
                type_axis = axes('Position', get(backend_axis, 'Position') .* [1 1 1 0.001] - [0 sqz 0 0],'Color','none');


                %scale_axis.XTickLabel = repmat(uintegral_scales, [1 length(aps) / length(uintegral_scales)]);
                %scale_axis.XTick = [1:length(aps)];

                cluster_axis.XTickLabel = repmat(uclusters, [1 length(aps) / length(uintegral_scales) / length(uclusters)]);
                observations_per_cluster = length(uintegral_scales);
                cluster_axis.XTick = [1:(length(ucodebook_types) * length(uclusters) * length(ubackends))] .* observations_per_cluster - (observations_per_cluster-1) / 2;

                backend_axis.XTickLabel = repmat(cellfun(@(x) strrep(x, '_', '-'), ubackends, 'UniformOutput', false), [1 length(aps) / length(uintegral_scales) / length(uclusters) / length(ubackends)]);
                observations_per_backend = length(uintegral_scales) * length(uclusters);
                backend_axis.XTick = [1:(length(ucodebook_types) * length(ubackends))] .* observations_per_backend - (observations_per_backend-1) / 2;

                type_axis.XTickLabel = ucodebook_types;
                observations_per_type = length(aps)/length(ucodebook_types);
                type_axis.XTick = [1:length(ucodebook_types)] .* observations_per_type - (observations_per_type-1) / 2;

                %linkaxes([scale_axis, backend_axis, cluster_axis, type_axis]);
                linkaxes([backend_axis, cluster_axis, type_axis]);
                % restorce gca for title
                %axes(scale_axis);
                axes(cluster_axis);
                set(f, 'Visible', 'Off');
                title(strrep(restrict_to, '_', '\_'), 'FontSize', 8);
                saveas(f, [srcdir filesep sprintf('performance_matrix-%s-%04d.pdf', scoring, pi)]);
                saveas(f, [srcdir filesep sprintf('performance_matrix-%s-%04d.png', scoring, pi)]);
            end
        end
    end
end

function measures = measureMy(params, groundTruth)
    info('Calculating graphs for my implementation');
    srcdir = [params.dataset.localdir filesep 'queries' filesep 'scaled'];

    valid_files = [groundTruth.positive] == 1;
    invalid_files = ~valid_files;

    valid_files = groundTruth(valid_files);
    valid_files = unique({valid_files.curid}, 'stable');

    invalid_files = groundTruth(invalid_files);
    invalid_files = {invalid_files.curid};

    all_files = horzcat(valid_files, invalid_files);
    labels = [ones([1 length(valid_files)]), zeros([1 length(invalid_files)])];

    info('Search result files');
    resultFiles = getAllFiles(srcdir, 'results.mat');
    debg('%d files found', length(resultFiles));

    measures = alloc_struct_array(length(resultFiles), 'imageap', 'bboxap', 'detections', 'path', 'curid');
    for ri=1:length(resultFiles)
        debg('[%4d/%04d]', ri, length(resultFiles));
        [path, ~, ~] = fileparts(resultFiles{ri});
        targetfile = [path filesep];

        if ~params.force_remeasure && exist([targetfile 'measure.mat'], 'file')
            load_ex([targetfile, 'measure.mat']);
        else
            load_ex(resultFiles{ri});
            if isempty(results)
                err('No results for %s', resultFiles{ri});
                continue;
            end
            results = results{1};
            if isempty(results)
                err('No results for %s', resultFiles{ri});
                continue;
            end
            % remove all empty results
            results = results(~cellfun(@isempty, {results.curid}));
            curid = unique({results.query_curid});
            if length(curid) > 1
                warn('Multiple query ids shouldn''t be possible @ %s', targetfile);
            end

            imageap = measureImageOnly(targetfile, results, all_files, labels, valid_files);
            [detections, bboxap] = measureBboxes(params, targetfile, results, groundTruth);

            save_ex([targetfile, 'measure.mat'], 'imageap', 'detections', 'bboxap', 'curid');
        end

        measures(ri).imageap = imageap;
        measures(ri).detections = detections;
        measures(ri).bboxap = bboxap;
        measures(ri).path = path;
        measures(ri).curid = curid;
        tmp = textscan(path, 'results/queries/scaled/%[^-]-Scoring/%[^-]-Backend/%d-Cluster/100-Imgs/%f-IntScale/%[^/]/%s');
        tmp{1} = tmp{1}{1};
        tmp{2} = tmp{2}{1};
        tmp{5} = tmp{5}{1};
        tmp{6} = tmp{6}{1};
        measures(ri).group = cell2struct(tmp, {'scoring', 'backend', 'cluster', 'integral_scale', 'codebook_type', 'rest'}, 2);
    end
    remove = cellfun(@isempty, {measures.curid});
    measures(remove) = [];
    save_ex([srcdir filesep 'measure.mat'], 'measures');
end

function measureExemplar(params, groundTruth)
    info('Calculating graphs for exemplar implementation');
    load_ex('../masato/timo2/data/imageFiles_database/002/results/exemplar_001/all_detects_sort_highest_score_exempl.mat', 'all_detects_sort_highest_score_exempl');

    fileids = {...
        '2007_008932',...
        '2008_000133',...
        '2008_000176',...
        '2008_000562',...
        '2008_000691',...
        '2008_002098',...
        '2008_002369',...
        '2008_002491',...
        '2008_003287',...
        '2008_003970',...
        '2008_004363',...
        '2008_004872',...
        '2008_005147',...
        '2008_005190',...
        '2008_007103',...
        '2008_008395',...
        '2008_008611',...
        '2008_008724',...
        '2009_000545',...
        '2009_000632',...
        '2009_000634',...
        '2009_000985',...
        '2009_002087',...
        '2009_002295',...
        '2009_002928',...
        '2009_002954',...
        '2009_003208',...
        '2009_004364',...
        '2009_004551',...
        '2009_004882',...
        '2009_004934',...
        '2010_000254',...
        '2010_000342',...
        '2010_001899',...
        '2010_002814',...
        '2010_003701',...
        '2010_004365',...
        '2010_004921',...
        '2010_005116',...
        '2010_005951',...
        '2010_006031',...
        '2010_006274',...
        '2010_006366',...
        '2010_006668',...
        '2011_000053',...
        '2011_001138',...
        '2011_001726',...
        '2011_002110',...
        '2011_002217',...
        '2011_004221'...
    };

    valid_files = [groundTruth.positive] == 1;
    invalid_files = ~valid_files;

    valid_files = groundTruth(valid_files);
    valid_files = unique({valid_files.curid}, 'stable');

    invalid_files = groundTruth(invalid_files);
    invalid_files = {invalid_files.curid};

    all_files = horzcat(valid_files, invalid_files);
    labels = [ones([1 length(valid_files)]), zeros([1 length(invalid_files)])];

    targetfolder = [params.dataset.localdir filesep 'exemplar' filesep];
    if ~exist(targetfolder, 'dir')
        mkdir(targetfolder);
    end
    copyfile('../masato/timo2/data/imageFiles_database/002/exemplar_000.jpg', [targetfolder 'query.jpg']);

    results = [fileids(all_detects_sort_highest_score_exempl(:, 11));...
               num2cell(all_detects_sort_highest_score_exempl(:, 1:4)', 1);...
               num2cell(all_detects_sort_highest_score_exempl(:, 12)')];
    results = cell2struct(results, {'curid', 'bbox', 'score'});

    imageap = measureImageOnly(targetfolder, results, all_files, labels, valid_files);
    [detections, bboxap] = measureBboxes(params, targetfolder, results, groundTruth);

    save_ex([targetfolder, 'measure.mat'], 'imageap', 'detections', 'bboxap');
end

function ap = measureImageOnly(targetfile, results, all_files, labels, valid_files)
    detected_files = unique({results.curid}, 'stable');
    found = cellfun(@(x) find(ismember(all_files, x)), detected_files);
    notfound = arrayfun(@(x) ~ismember(x, found), 1:50);
    detected_files = [detected_files, repmat({''}, [1 length(all_files) - length(detected_files)])];

    newlabels = [labels(found), labels(notfound)] == 1;

%         tps = cumsum(newlabels);
%         tps = tps(1:length(detected_files));

%         tp = cellfun(@(x) ismember(x, valid_files), detected_files);
%         fp = ~tp & ~cellfun(@isempty, detected_files);
%         fn = cellfun(@(x) ~ismember(x, detected_files), valid_files);
%         tn = cellfun(@(x) ~ismember(x, detected_files), invalid_files);

%         retrieved_relevant = cumsum(tp);
    %retrieved_relevant = [retrieved_relevant, repmat(retrieved_relevant(end), [1 length(all_files) - size(retrieved_relevant, 2)])];
%         retrieved = 1:length(all_files);
%         expected_relevant = 1:length(valid_files);
%         expected_relevant = [expected_relevant, repmat(expected_relevant(end), [1 length(all_files) - size(expected_relevant, 2)])];

%         precision = [1 retrieved_relevant] ./ [1 (1:length(tp))];
%         recall = [0 retrieved_relevant] / length(tp);

    ap = savePR([targetfile, 'precision_recall_imageonly-%.3f-AP'], newlabels, (length(all_files):-1:1) .* ~cellfun(@isempty, detected_files), length(valid_files));
end


function [detections, ap] = measureBboxes(params, targetfile, results, groundTruth)
% calc overlap between found bbox and label bboxes per image
% if overlap > 0.5 -> 1 if label bbox already detected -> 0

    scores = horzcat(results.score);

    tmp = {groundTruth.curid};
    lookup = cellfun(@(x) find(ismember(tmp, x)), {results.curid}, 'UniformOutput', false);

    labels = false([1 length(results)]);
    detected = false([1 length(groundTruth)]);
    for ri=1:length(results)
        result = results(ri);

        currentgt = lookup{ri};
        gts = groundTruth(currentgt);

        for gi=1:length(gts)
            if gts(gi).positive
                if pascal_overlap(gts(gi).bbox, result.bbox) > 0.5
                    if ~detected(currentgt(gi))
                        labels(ri) = true;
                        detected(currentgt(gi)) = true;
                    end
                end
            end
        end
    end
    detections = sum(labels);
    info('Detections: %d/%d', detections, sum(horzcat(groundTruth.positive)));

    ap = savePR([targetfile, 'precision_recall_bboxes-%.3f-AP'], labels, scores, sum(horzcat(groundTruth.positive)));
end

function ap = savePR(targetfile, labels, scores, expected_relevant)
    [ precision, recall, thresholds ] = precision_recall(labels, scores, expected_relevant);
    ap = average_precision(labels, scores, expected_relevant);
    info('Average Precision: %f', ap);
    f = figure('Visible', 'Off');
    plot(recall, precision);
    ylim([-0.1 1.1]);
    xlim([-0.1 1.1]);
    title(sprintf('Average Precision: %.3f', ap));
    saveas(f, [sprintf(targetfile, ap) '.png']);
    saveas(f, [sprintf(targetfile, ap) '.pdf']);
    close(f);
    info('Saved graph in %s', targetfile);
end

function fileList = getAllFiles(dirName, ext, max_files)
  if ~exist('ext', 'var')
      ext = '';
  end
  if ~exist('max_files', 'var')
      max_files = -1;
  end
  dirData = dir(dirName);      %# Get the data for the current directory
  dirIndex = [dirData.isdir];  %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
  if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
                       fileList,'UniformOutput',false);

    if ~isempty(ext)
        validIndex = cellfun(@(x) endswith(x, ext), fileList);
        fileList = fileList(validIndex);
    end

    if max_files >= 0
        max_files = max_files - length(fileList);
        if max_files <= 0
            fileList = fileList(length(fileList) + max_files);
            return;
        end
    end
  end
  subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = [fileList; getAllFiles(nextDir, ext, max_files)];  %# Recursively call getAllFiles

    if max_files >= 0
        max_files = max_files - length(fileList);
        if max_files <= 0
            fileList = fileList(1:length(fileList) + max_files);
            return;
        end
    end
  end
end

function tf = endswith(str, suffix)
% Return true if the string ends in the specified suffix
% This file is from matlabtools.googlecode.com

    n = length(suffix);
    if length(str) < n
        tf =  false;
    else
        tf = strcmp(str(end-n+1:end), suffix);
    end
end

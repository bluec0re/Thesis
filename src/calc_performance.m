function calc_performance()
    addpath(genpath('src'));
    addpath(genpath('vendors'));
    params = get_default_configuration;
    params.log_file = '/dev/null';
    params.log_level = 'debug';
    log_level(params.log_level);

    ground_truth = load_groundtruth(params);
    my(params, ground_truth);
    exemplarSVM(params, ground_truth);
end

function my(params, ground_truth)
    load('results/performance/windows.mat');
    unique_images = unique({ground_truth.curid});

    expected_matches = [ground_truth.positive];
    expected_matches = sort(expected_matches, 'descend') == 1;
    for si=1:length(results)
        debg('%3d/%03d', si, length(results));
        comb = combinations{si};
        result = results{si};

        [~, i] = sort([result.score], 'descend');
        result = result(i);
        matches = score_images(params, result, ground_truth);
        scores_pascal = score_bbox(params, result, ground_truth);

        windows = round(mean([result.num_windows]) / length(unique_images))
        filename = sprintf('%s_%d-Parts_%d-Clusters_%d-Windows',...
                           comb{3}, comb{2}, comb{1}, windows);
        %savePR(expected_matches, matches .* [result.score], ['image/' filename]);
        %savePR(expected_matches, (scores_pascal > 0) .* [result.score], ['bbox/' filename]);
        %savePR(expected_matches, (scores_pascal >= 0.5) .* [result.score], ['bbox-50percent_overlap/' filename]);
        savePR(matches, [result.score], ['image/' filename]);
        savePR(scores_pascal > 0, [result.score], ['bbox/' filename]);
        savePR(scores_pascal >= 0.5, [result.score], ['bbox-50percent_overlap/' filename]);
    end
end

function savePR(labels, scores, filename, additional_title)
    labels = [labels, false([1, length(scores) - length(labels)])];
    [precision, recall, thresholds] = precision_recall(labels, scores, sum(labels));
    ap = average_precision(labels, scores, sum(labels));

    info('Average Precision: %f', ap);
    debg('#Positive: %d', sum(labels));
    f = figure('Visible', 'Off', 'PaperUnits', 'centimeters', 'PaperPosition', [0, 0, 10, 7]);
    plot(recall, precision);
    xlabel('Recall');
    ylabel('Precision');
    ylim([-0.1 1.1]);
    xlim([-0.1 1.1]);
    if ~exist('additional_title', 'var')
        figtitle = sprintf('Avg Precision: %.3f', ap);
        title(figtitle);
    else
        figtitle = sprintf('Avg Precision: %.3f\n%s', ap, additional_title);
        title(figtitle, 'FontSize', 10);
    end

    fullname = ['results/performance/' filename];
    [path, ~, ~] = fileparts(fullname);
    if ~exist(path, 'dir')
        mkdir(path);
    end

    saveas(f, [fullname '.png']);
    %saveas(f, [fullname '.pdf']);
    close(f);
    info('Saved graph in %s', filename);
end

function matches = score_images(params, results, ground_truth)
    positives = [ground_truth.positive] == 1;
    valid_files = {ground_truth(positives).curid};
    invalid_files = {ground_truth(~positives).curid};

    matches = false([1 length(results)]);
    for ir=1:length(results)
        result = results(ir);
        found = ismember(valid_files, result.curid);
        if any(found)
            matches(ir) = true;
            % only one match allowed
            found = find(found);
            valid_files(found(1)) = [];
        end
    end
end

function scores_pascal = score_bbox(params, results, ground_truth)
    scores_pascal = zeros([1 length(results)]);
    files = {ground_truth.curid};
    for ir=1:length(results)
        result = results(ir);
        found = ismember(files, result.curid);
        gt = ground_truth(found);
        last = 0;
        for gi=1:length(gt)
            if gt(gi).positive
                score = pascal_overlap(gt(gi).bbox, result.bbox);
                if scores_pascal(ir) < score
                    scores_pascal(ir) = score;
                    last = gi;
                end
            end
        end
        if last > 0
            toremove = strcmp({ground_truth.curid}, result.curid);
            toremove = toremove & [ground_truth.objectid] == gt(last).objectid;
            ground_truth(toremove) = [];
            files(toremove) = [];
        end
    end
end

function exemplarSVM(params, ground_truth)
    info('Calculating graphs for exemplar implementation');

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

    load_ex('../masato/timo2/data/imageFiles_database/006/results/exemplar_001/all_detects_sort_highest_score_exempl.mat', 'all_detects_sort_highest_score_exempl');
    % map exemplar results into struct array
    results = [fileids(all_detects_sort_highest_score_exempl(:, 11));...
               num2cell(all_detects_sort_highest_score_exempl(:, 1:4)', 1);...
               num2cell(all_detects_sort_highest_score_exempl(:, 12)')];
    results = cell2struct(results, {'curid', 'bbox', 'score'});

    [~, i] = sort([results.score], 'descend');
    results = results(i);

    load_ex('../masato/timo2/results.mat', 'elapsed_time', 'extract_time', 'num_windows');

    unique_images = unique({ground_truth.curid});

    expected_matches = [ground_truth.positive];
    expected_matches = sort(expected_matches, 'descend') == 1;

    matches = score_images(params, results, ground_truth);
    scores_pascal = score_bbox(params, results, ground_truth);

    filename = 'exemplarSVM';
    additional_title = sprintf('Avg Time per Image: %.3fs\nAvg #Windows: %d', extract_time/length(fileids), mean(num_windows));
    %savePR(expected_matches, matches .* [results.score], ['image/' filename], additional_title);
    %savePR(expected_matches, (scores_pascal > 0) .* [results.score], ['bbox/' filename], additional_title);
    %savePR(expected_matches, (scores_pascal >= 0.5) .* [results.score], ['bbox-50percent_overlap/' filename], additional_title);
    savePR(matches, [results.score], ['image/' filename], additional_title);
    savePR(scores_pascal > 0, [results.score], ['bbox/' filename], additional_title);
    savePR(scores_pascal >= 0.5, [results.score], ['bbox-50percent_overlap/' filename], additional_title);
end

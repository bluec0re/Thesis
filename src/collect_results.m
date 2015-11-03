function collect_results(varargin)
%COLLECT_RESULTS Collects all results from the results/queries folder and computes AVG-PR

    params = get_default_configuration;
    keywords = parse_keywords(varargin, fieldnames(params));
    params = merge_structs(params, keywords);
    log_file('/dev/null');
    log_level('debug');

    srcdir = [params.dataset.localdir filesep 'queries' filesep 'scaled'];

    info('Search result files');
    resultFiles = getAllFiles(srcdir, 'results.mat');
    debg('%d files found', length(resultFiles));
    groundTruth = getDatabase(params);

    M = {'params', 'ap-bbox', 'ap-img', 'time'};
    fp = fopen([params.dataset.localdir filesep 'results.csv'], 'w');
    fprintf(fp, 'params,ap-bbox,ap-img,time\n');
    for ri=1:length(resultFiles)
        load(resultFiles{ri});
        results = results{1};

        if isempty(results)
            continue
        end

        ps = {};
        fields = fieldnames(cleanparams);
        for fi=1:length(fields)
            if islogical(cleanparams.(fields{fi}))
                if cleanparams.(fields{fi})
                    ps{end+1} = [fields{fi} '=true'];
                else
                    ps{end+1} = [fields{fi} '=false'];
                end
            elseif isnumeric(cleanparams.(fields{fi}))
                ps{end+1} = [fields{fi} '=' num2str(cleanparams.(fields{fi}))];
            else
                ps{end+1} = [fields{fi} '=' cleanparams.(fields{fi})];
            end
        end

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
        bboxdetections = sum(labels);
        expected_relevant = sum(horzcat(groundTruth.positive));
        info('Detections: %d/%d', bboxdetections, expected_relevant);
        apBBox = average_precision(labels, scores, expected_relevant);


        valid_files = [groundTruth.positive] == 1;
        invalid_files = ~valid_files;

        valid_files = groundTruth(valid_files);
        valid_files = unique({valid_files.curid}, 'stable');

        invalid_files = groundTruth(invalid_files);
        invalid_files = {invalid_files.curid};

        all_files = horzcat(valid_files, invalid_files);
        labels = [ones([1 length(valid_files)]), zeros([1 length(invalid_files)])];

        detected_files = unique({results.curid}, 'stable');
        found = cellfun(@(x) find(ismember(all_files, x)), detected_files);
        notfound = arrayfun(@(x) ~ismember(x, found), 1:50);
        detected_files = [detected_files, repmat({''}, [1 length(all_files) - length(detected_files)])];

        labels = [labels(found), labels(notfound)] == 1;
        scores = (length(all_files):-1:1) .* ~cellfun(@isempty, detected_files);
        expected_relevant = length(valid_files);
        apImg = average_precision(labels, scores, expected_relevant);

        fprintf(fp, '%s,%f,%f,%f\n', strjoin(ps, ';'), apBBox, apImg, elapsed_time);
    end
    fclose(fp);
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

function files = getDatabase(params)
    info('Loading ground truth');
    filename = sprintf(params.dataset.clsimgsetpath, params.class, 'database');
    f = fopen(filename, 'r');
    fileList = textscan(f, '%s %d');
    fclose(f);

    fnames = fileList{1};
    positives = fileList{2};
    objectidx = 1;
    for fli=1:length(fnames)
        fname = fnames{fli};
        positive = positives(fli);

        anno = sprintf(params.dataset.annopath, fname);
        anno = PASreadrecord(anno);
        objid = 1;
        for obj = anno.objects
            if strcmp(obj.class, params.class)
                files(objectidx).curid = fname;
                files(objectidx).I = sprintf(params.dataset.imgpath, fname);
                files(objectidx).positive = positive == 1;
                files(objectidx).bbox = obj.bbox;
                files(objectidx).objectid = objid;
                objectidx = objectidx + 1;
                objid = objid + 1;
            end
        end

        if ~positive
            files(objectidx).curid = fname;
            files(objectidx).I = sprintf(params.dataset.imgpath, fname);
            files(objectidx).positive = positive;
            files(objectidx).bbox = [];
            files(objectidx).objectid = objid;
            objectidx = objectidx + 1;
        end
    end
end

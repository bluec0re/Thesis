function files = load_groundtruth(params)
%LOAD_GROUNDTRUTH Loads the groundtruth from the database list
%
%   Syntax:     files = load_groundtruth(params)
%
%   Input:
%       params - Configuration with dataset, class and db_stream_name set
%
%   Output:
%       files  - Struct array if files with fields: curid, I, positive, bbox, objectid
    info('Loading ground truth');
    filename = sprintf(params.dataset.clsimgsetpath, params.class, params.db_stream_name);
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

function files = load_groundtruth(params)
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

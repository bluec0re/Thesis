

clusters = [1000, 512];
ids = {'2007_008932', '2008_000133'}
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
total_cells = zeros([2 length(fileids)]);
total_pixels = zeros([2 length(fileids)]);
naiive_cells_filled = zeros([2 length(fileids)]);
sparse_cells_filled = zeros([2 length(fileids)]);
naiive_pixels_filled = zeros([2 length(fileids)]);
sparse_pixels_filled = zeros([2 length(fileids)]);
sparse_codebook_cells_filled = zeros([2 length(fileids)]);
for iid=1:length(fileids)
    for c=1:2
        id = fileids{iid}
        cluster = clusters(c)

        load(['/export/home/tschmid/thesis2/results/models/codebooks/integral/naiive/images/' num2str(cluster) '--' id '-0-full-1.000-double-3-86x86.mat']);
        ni = integral;
        if ~isfield(ni, 'I_size')
            ni.I_size = size(ni.I);
        end
        load(['/export/home/tschmid/thesis2/results/models/codebooks/integral/sparse/images/' num2str(cluster) '--' id '-0-full-1.000-double-3-86x86.mat']);

        si = integral;

        if iid == 1 && c == 1
            tmp = tic;
            I = zeros(si.I_size);
            I(si.idx) = si.scores;
            I = reconstruct_matrix(I);
            reconstruct_time = toc(tmp)
            same_matrices = all(all(all(I == ni.I)))
        end

        ni.I_size
        si.I_size
        total_cells(c,iid) = prod(ni.I_size)
        total_pixels(c,iid) = prod(ni.I_size([3 4]))
        naiive_cells_filled(c,iid) = sum(ni.I(:) ~= 0)
        naiive_cells_filled(c,iid) / total_cells(c,iid) * 100
        sparse_cells_filled(c,iid) = length(si.idx)
        sparse_cells_filled(c,iid) / total_cells(c,iid) * 100


        naiive_pixels = squeeze(any(ni.I, 2));
        naiive_pixels_filled(c,iid) = sum(naiive_pixels(:))
        naiive_pixels_filled(c,iid) / total_pixels(c,iid) * 100

        % tmp = tic;
        % for i=100
        %     I = zeros(si.I_size);
        %     I(:) = 10;
        % end
        % matrix_full_fill_sec = toc(tmp) / 100
        %
        % tmp = tic;
        % for i=1000
        %     I = zeros(si.I_size);
        %     I(si.idx) = si.scores;
        % end
        % matrix_sparse_fill_sec = toc(tmp) / 100
        I = zeros(si.I_size);
        I(si.idx) = si.scores;
        sparse_pixels = squeeze(any(I, 2));
        sparse_pixels_filled(c,iid) = sum(naiive_pixels(:))
        sparse_pixels_filled(c,iid) / total_pixels(c,iid) * 100

        I = ni.I;
        I(:, :, find(~sparse_pixels)) = 0;
        sparse_codebook_cells_filled(c,iid) = sum(I(:) ~= 0)
        sparse_codebook_cells_filled(c,iid) / total_cells(c,iid) * 100
    end
end

tmp = tic;
I = zeros(si.I_size);
I(si.idx) = si.scores;
I = reconstruct_matrix(I);
reconstruct_time = toc(tmp);
same_matrices = all(all(all(I == ni.I)))

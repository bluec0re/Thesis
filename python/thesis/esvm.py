from h5py import File as loadhdf
from scipy.io import loadmat
from collections import namedtuple

from .metrics import get_average_precision
from .config import ESVM_IDS, ESVM_FILES, FILES, ESVM_PATH
from .utils import BoundingBox, Result, get_mean

Baseline = namedtuple('Baseline', 'elapsed, extract, windows, average_precision, recall_threshold')


def get_baseline(img=None):
    """
    Loads ESVM results
    """
    data = []
    files = tuple(ESVM_IDS[f-1] for f in ESVM_FILES)
    if not img:
        img = FILES
    elif isinstance(img, str):
        img = [img]

    for i in img:
        i = files.index(i) + 9
        filename = ESVM_PATH / 'data' / 'imageFiles_database' / '{:03}'.format(i) / 'results' / \
            'exemplar_001' / 'all_detects_sort_highest_score_exempl.mat'

        if not filename.exists():
            continue

        with loadhdf(str(filename)) as mat:
            results = mat['all_detects_sort_highest_score_exempl'].value

        results2 = []
        for i in range(results.shape[1]):
            r = results[(10, 11, 0, 1, 2, 3), i]
            r = Result(ESVM_IDS[int(r[0])-1], r[1], BoundingBox(*map(int, (r[2:]-1))))
            results2.append(r)

        [avg_precision, threshold] = get_average_precision(results2)

        mat = loadmat(str(ESVM_PATH / 'results.mat'))

        data.append(Baseline(
                float(mat['elapsed_time']),
                float(mat['extract_time']),
                mat['num_windows'][:, 0].mean(),
                avg_precision,
                threshold))
    return get_mean(data, 'windows')[0]

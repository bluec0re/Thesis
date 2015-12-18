from h5py import File as loadhdf
from scipy.io import loadmat
from collections import namedtuple

from .metrics import get_average_precision
from .config import (ESVM_IDS1, ESVM_IDS2, ESVM_IDS3,
                     ESVM_FILES1, ESVM_FILES2, ESVM_FILES3,
                     FILES, ESVM_PATH, ALL_FILES,
                     ESVM_DATABASE1, ESVM_DATABASE2, ESVM_DATABASE3,
                     ESVM_START_INDEX1, ESVM_START_INDEX2, ESVM_START_INDEX3)
from .utils import BoundingBox, Result, get_mean

Baseline = namedtuple('Baseline', 'elapsed, extract, windows, average_precision, recall_threshold')


def get_baseline(database, img=None):
    """
    Loads ESVM results
    """
    if database == 'database':
        ESVM_IDS = ESVM_IDS1
        ESVM_FILES = ESVM_FILES1
        ESVM_START_INDEX = ESVM_START_INDEX1
        ESVM_DATABASE = ESVM_DATABASE1
    elif database == 'database2':
        ESVM_IDS = ESVM_IDS2
        ESVM_FILES = ESVM_FILES2
        ESVM_START_INDEX = ESVM_START_INDEX2
        ESVM_DATABASE = ESVM_DATABASE2
    elif database == 'val':
        ESVM_IDS = ESVM_IDS3
        ESVM_FILES = ESVM_FILES3
        ESVM_START_INDEX = ESVM_START_INDEX3
        ESVM_DATABASE = ESVM_DATABASE3
    data = []
    files = tuple(ESVM_IDS[f-1] for f in ESVM_FILES)
    if not img:
        img = FILES
    elif img == 'ALL':
        img = ALL_FILES
    elif isinstance(img, str):
        img = [img]

    for i in img:
        i = files.index(i) + ESVM_START_INDEX
        filename = ESVM_DATABASE / '{:03}'.format(i) / 'results' / \
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

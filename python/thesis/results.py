from scipy.io import loadmat
from collections import namedtuple

from .metrics import get_average_precision
from .config import TIMING_PATH
from .utils import BoundingBox, Result


MyLine = namedtuple('MyLine', 'elapsed, extract, windows, average_precision, win_type')


def get_results(clusters, parts, filtered, scale_ranges, win_img_ratio, query_src,
                fileid, nonmax, database, recall_threshold):
    """
    Load timing results
    """
    path = TIMING_PATH
    if True or database != 'database':
        path /= database
    filename = path / "total-{}-{}-{}-{}-{:.2f}-{}-{}-{}.mat".format(clusters,
                                                                     parts,
                                                                     filtered,
                                                                     scale_ranges,
                                                                     win_img_ratio,
                                                                     query_src,
                                                                     fileid,
                                                                     nonmax)
    try:
        mat = loadmat(str(filename))
    except IOError:
        if nonmax == 'min':
            mat = loadmat(str(filename).replace('-min', ''))
        else:
            raise
    results = mat['results'][0, :]
    num_windows = mat['num_windows'][0, :]
    elapsed_time = mat['elapsed_time'][0, :]

    mylines = []
    for win_type, (r, nw, elapsed_time1) in enumerate(zip(results, num_windows, elapsed_time)):
        nw = int(nw)
        # computation not finished
        if nw == 0:
            continue

        # get results
        r = r[0, 0][0, :]

        # Transform into object
        results2 = []
        for r1 in r:
            r1 = Result(r1['curid'][0], r1['score'][0, 0],
                        BoundingBox(*map(int, (r1['bbox'][0, :] - 1))))
            results2.append(r1)
        # print("#Results:", len(results2))
        avg_precision, _ = get_average_precision(results2, recall_threshold)
        # print("Average Precision:", avg_precision)

        mylines.append(MyLine(
            elapsed_time1,
            None,
            nw,
            avg_precision,
            win_type
        ))

    return mylines

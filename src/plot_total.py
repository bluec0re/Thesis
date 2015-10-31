#!/usr/bin/env python3
# encoding: utf-8
import numpy as np
import matplotlib.pyplot as plt
from collections import namedtuple
from scipy.io import loadmat
from scipy.misc import imread
from pathlib import Path as P
from h5py import File as loadhdf
from xml.etree import ElementTree as ET
from sklearn.metrics import average_precision_score, auc
from sklearn.preprocessing import normalize
from pprint import pprint
from itertools import product, cycle
import sys


ROOT = P(__file__).absolute().parent.parent
ESVM_PATH = ROOT / '..' / 'masato' / 'timo2'
RESULT_PATH = ROOT / 'results'
PASCAL_PATH = ROOT / 'DBs' / 'Pascal' / 'VOC2011'
IMAGE_PATH = PASCAL_PATH / 'JPEGImages'
TIMING_PATH = RESULT_PATH / 'timings'
PERFORMANCE_PATH = RESULT_PATH / 'performance'

Baseline = namedtuple('Baseline', 'elapsed, extract, windows, average_precision, recall_threshold')
GroundData = namedtuple('GroundData', 'fileid, I, positive, bbox, objectid')
BoundingBox = namedtuple('BoundingBox', 'x_min, y_min, x_max, y_max')
Result = namedtuple('Result', 'fileid, score, bbox')
MyLine = namedtuple('MyLine', 'elapsed, extract, windows, average_precision, win_type')
FILES = ('2008_004363', '2009_004882', '2010_005116', '2009_000634', '2010_003701')
ESVM_FILES = (11, 30, 39, 21, 36)
ESVM_IDS = (
    '2007_008932',
    '2008_000133',
    '2008_000176',
    '2008_000562',
    '2008_000691',
    '2008_002098',
    '2008_002369',
    '2008_002491',
    '2008_003287',
    '2008_003970',
    '2008_004363',
    '2008_004872',
    '2008_005147',
    '2008_005190',
    '2008_007103',
    '2008_008395',
    '2008_008611',
    '2008_008724',
    '2009_000545',
    '2009_000632',
    '2009_000634',
    '2009_000985',
    '2009_002087',
    '2009_002295',
    '2009_002928',
    '2009_002954',
    '2009_003208',
    '2009_004364',
    '2009_004551',
    '2009_004882',
    '2009_004934',
    '2010_000254',
    '2010_000342',
    '2010_001899',
    '2010_002814',
    '2010_003701',
    '2010_004365',
    '2010_004921',
    '2010_005116',
    '2010_005951',
    '2010_006031',
    '2010_006274',
    '2010_006366',
    '2010_006668',
    '2011_000053',
    '2011_001138',
    '2011_001726',
    '2011_002110',
    '2011_002217',
    '2011_004221'
)


def breakpoint():
    import pdb
    pdb.Pdb().set_trace(sys._getframe().f_back)


class GroundTruth:
    pascal_class = 'bicycle'
    data = None
    positives = []
    negatives = []

    def __init__(self, data):
        self._data = data[:]

    def __getitem__(self, name):
        results = []
        for gd in self._data:
            if gd.fileid == name:
                results.append(gd)
        return tuple(results)

    def __iter__(self):
        return iter(self._data)

    def delete(self, fileid, objectid):
        for i, gd in enumerate(self._data):
            if gd.fileid == fileid and gd.objectid == objectid:
                self._data.pop(i)
                break

    def pop(self):
        return self._data.pop()

    def __len__(self):
        return len(self._data)

    @classmethod
    def get(cls):
        if not cls.data:
            cls.load()
        return GroundTruth(cls.data)

    @classmethod
    def load_ids(cls):
        with (ROOT / "data" / "{}_database.txt".format(cls.pascal_class)).open() as fp:
            for line in fp:
                id, type = line.split()
                if type == '1':
                    cls.positives.append(id)
                else:
                    cls.negatives.append(id)

    @classmethod
    def load(cls):
        cls.load_ids()
        annopath = PASCAL_PATH / 'Annotations'
        imgpath = PASCAL_PATH / 'JPEGImages'
        cls.data = []
        for fileid in cls.positives + cls.negatives:
            xml = ET.parse(str(annopath / (fileid + '.xml')))
            objid = 0
            for obj in xml.iterfind('object'):
                if obj.find('name').text == cls.pascal_class:
                    bndbox = obj.find('bndbox')
                    bndbox = BoundingBox(
                        int(bndbox.find('xmin').text)-1,
                        int(bndbox.find('ymin').text)-1,
                        int(bndbox.find('xmax').text)-1,
                        int(bndbox.find('ymax').text)-1,
                    )
                    gd = GroundData(
                        fileid,
                        imgpath / "{}.jpg".format(fileid),
                        fileid in cls.positives,
                        bndbox,
                        objid+1
                    )
                    cls.data.append(gd)
                    objid += 1

            if fileid in cls.negatives or objid == 0:
                gd = GroundData(
                    fileid,
                    imgpath / "{}.jpg".format(fileid),
                    fileid in cls.positives,
                    None,
                    objid
                )
                cls.data.append(gd)


def pascal_overlap(A, B):
    """
    >>> pascal_overlap(BoundingBox(0, 0, 10, 10), BoundingBox(0, 0, 10, 10))
    1.0
    >>> pascal_overlap(BoundingBox(0, 0, 10, 20), BoundingBox(0, 0, 10, 10))
    0.5
    >>> pascal_overlap(BoundingBox(0, 0, 10, 10), BoundingBox(0, 5, 10, 10))
    0.5
    >>> pascal_overlap(BoundingBox(0, 0, 10, 5), BoundingBox(0, 5, 10, 10))
    0
    """
    dx = int(min(A.x_max, B.x_max) - max(A.x_min, B.x_min))
    dy = int(min(A.y_max, B.y_max) - max(A.y_min, B.y_min))
    if dy > 0 and dx > 0:
        intersectionArea = dx * dy
    else:
        return 0

    dx = int(max(A.x_max, B.x_max) - min(A.x_min, B.x_min))
    dy = int(max(A.y_max, B.y_max) - min(A.y_min, B.y_min))
    if dy > 0 and dx > 0:
        unionArea = dx * dy
    else:
        unionArea = 0
    overlap = intersectionArea / unionArea
    return overlap


def get_average_precision1(results):
    gt = GroundTruth.get()
    labels = []
    scores = []
    for r in results:
        score = r.score
        scores.append(score)
        best = (0, None)
        for gd in gt[r.fileid]:
            if not gd.positive:
                continue

            pascal_score = pascal_overlap(gd.bbox, r.bbox)
            if pascal_score > best[0]:
                best = pascal_score, gd
        if best[1]:
            gd = best[1]
            gt.delete(gd.fileid, gd.objectid)
        labels.append(any(gd.positive for gd in gt[r.fileid]))
        if best[0] < 0.5:
            scores[-1] = 0

    return average_precision_score(labels, scores)


def adjust_vectors(labels, scores, expected_len, gt):
    return labels, scores

    if labels.shape[0] > expected_len:
        print("Removing last", labels.shape[0] - expected_len, "results")
        labels = labels[:expected_len]
        scores = scores[:expected_len]

    if labels.shape[0] < expected_len:
        print("Adding", expected_len - labels.shape[0], "missing labels")

    while labels.shape[0] < expected_len:
        for p in GroundTruth.positives:
            gd = gt[p]
            if len(gd) > 0:
                gd = gd[0]
                labels = np.append(labels, [gd.positive])
                gt.delete(gd.fileid, gd.objectid)
                break
        else:
            raise RuntimeError('Asking for more data than available: {} labels'.format(len(labels)))
        scores = np.append(scores, [False])
    return labels, scores


def get_average_precision2(results, threshold=None):
    gt = GroundTruth.get()
    labels = []
    scores = []
    for r in results:
        score = r.score
        scores.append(score)
        best = (0, None)
        for gd in gt[r.fileid]:
            if not gd.positive:
                continue

            pascal_score = pascal_overlap(gd.bbox, r.bbox)
            if pascal_score > best[0]:
                best = pascal_score, gd
        gd = best[1]
        if gd:
            gt.delete(gd.fileid, gd.objectid)
        labels.append(best[0] >= 0.5)
    # add penality if needed for to few images
    labels = np.array(labels)
    scores = np.array(scores)
    indices = list(reversed(np.argsort(scores)))
    labels = labels[indices]
    scores = scores[indices]

    expected_len = sum(1 if gd.positive else 0 for gd in GroundTruth.data)
    # print(scores)
    # variant 1: consider all as match -> bad for esvm
    scores = np.ones(scores.shape, dtype=bool)
    # variant 2: normalize values
    # scores = (scores - scores.min()) / (scores.max() - scores.min())
    [labels, scores] = adjust_vectors(labels, scores, expected_len, gt)
    # print(labels)
    # print(scores)
    # print('#Positive:', labels.sum())
    # ap = average_precision_score(labels, scores)
    precisions = np.cumsum(labels) / np.arange(1, labels.shape[0]+1)
    # precisions = np.insert(precisions, 0, [1.0])
    # precisions = np.append(precisions, [0.0])
    recalls = np.cumsum(labels) / expected_len
    # recalls = np.insert(recalls, 0, [0.0])
    # recalls = np.append(recalls, [1])

    if threshold is None:
        ratios = precisions / recalls
        query = (ratios > 0.5) | np.isnan(ratios)
        if np.all(query):
            idx = len(recalls)-1
        else:
            idx = np.argmin(query)
        threshold = recalls[idx]
    else:
        idx = np.argmax(recalls > threshold)
    recalls = recalls[:idx+1]
    precisions = precisions[:idx+1]
    ap2 = auc(recalls, precisions)
    # plt.subplots()[1].plot(recalls, precisions)
    return [ap2, threshold]


get_average_precision = get_average_precision2


def get_baseline(img=None):
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


def get_results(clusters, parts, filtered, scale_ranges, win_img_ratio, query_src,
                fileid, nonmax, database, recall_threshold):
    path = TIMING_PATH
    if database != 'database':
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
        if nw == 0:
            continue

        # print(win_type, "#Windows:", nw)
        r = r[0, 0][0, :]

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


def get_mean(in_results, field):
    fields = set([])
    for ir in in_results:
        fields.add(getattr(ir, field))
    out_results = []
    for f in fields:
        r = {field: f}
        num = 0
        for ir in in_results:
            other_fields = (of for of in ir._fields if of != field)
            if getattr(ir, field) == f:
                num += 1
                for of in other_fields:
                    if getattr(ir, of):
                        r[of] = r.get(of, 0) + getattr(ir, of)
                    else:
                        r[of] = 0
        for of in r.keys():
            if of == field:
                continue
            r[of] /= num

        r = type(in_results[0])(**r)
        out_results.append(r)

    return out_results


def process_database(database):
    for img in FILES:
        bl = get_baseline(img)
        print("Baseline precision:", bl.average_precision)

        for nonmax in ('union', 'min'):
            for scale_ranges in (1, 3):
                timing_folder = TIMING_PATH / database / nonmax / str(scale_ranges)
                if not timing_folder.exists():
                    timing_folder.mkdir(parents=True)

                perf_folder = PERFORMANCE_PATH / database / nonmax / str(scale_ranges)
                if not perf_folder.exists():
                    perf_folder.mkdir(parents=True)

                fig_all_perf, ax_all_perf = plt.subplots(1, 2)
                ax_all_perf[0].set_xlabel('Number of Windows')
                ax_all_perf[0].set_ylabel('Average Precision')
                # ax_all_perf.set_ylim((0, 1.1))
                fig_all_perf.suptitle('50% Bounding Box Overlap Required')
                fig_all_perf.canvas.set_window_title('All Performance - ' + img)

                fig_all_time, ax_all_time = plt.subplots()
                ax_all_time.set_xlabel('Number of Windows')
                ax_all_time.set_ylabel('Processing Time in Seconds')
                fig_all_time.suptitle('50% Bounding Box Overlap Required')
                fig_all_time.canvas.set_window_title('All Timings - ' + img)
                x_all = set([])
                marker = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))
                marker2 = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))

                for clusters, parts, filtered, win_img_ratio, query_src in product((512, 1000),
                                                                                   (1, 4),
                                                                                   ('filtered', 'unfiltered'),
                                                                                   (1, 0.75),
                                                                                   ('integral', 'raw')):
                    # img_results = []
                    # for img in FILES:
                    #     try:
                    #         img_results += get_results(clusters, parts, filtered, scale_ranges,
                    #                                    win_img_ratio, query_src, img, None)
                    #     except IOError as e:
                    #         print("Load error", e)
                    #         continue
                    # print("Loaded", len(img_results), "/", len(FILES), "results")
                    # if not img_results:
                    #     continue
                    # results = get_mean(img_results, 'win_type')

                    try:
                        results = get_results(clusters, parts, filtered, scale_ranges,
                                              win_img_ratio, query_src, img, nonmax, database, None)
                    except IOError as e:
                        print("Load error", e)
                        continue

                    x = [r.windows for r in results]
                    idx = np.argsort(x)
                    x.sort()
                    x_all |= set(x)
                    precisions = [results[i].average_precision for i in idx]
                    print(precisions)

                    title = '{}-{}-{}'.format(clusters, parts, scale_ranges)
                    if win_img_ratio != 1:
                        title += "-{}".format(win_img_ratio)
                    if filtered == 'filtered':
                        title += ', Window Filter'
                    if query_src == 'raw':
                        title += ', Raw'
                    print("Graph:", title)

                    # performance
                    fig, ax = plt.subplots()
                    ax.plot(x, [bl.average_precision]*len(x), 'r--',
                            label='ExemplarSVM', linewidth=2)
                    ax.plot(x, precisions, 'go-')
                    ax_all_perf[0].plot(x, precisions, linestyle='-', marker=next(marker), label=title)
                    ax.set_xlabel('Number of Windows')
                    ax.set_ylabel('Average Precision')
                    ax.set_ylim((None, max(precisions) * 1.1))
                    ax.legend(('ExemplarSVM', title), loc='lower right')
                    fig.suptitle('50% Bounding Box Overlap Required')
                    fig.savefig(str(perf_folder / "window_comparison-{}-{}-{}-{}-{}-{}.png".format(clusters,
                                                                                                   parts,
                                                                                                   filtered,
                                                                                                   win_img_ratio,
                                                                                                   query_src,
                                                                                                   nonmax)))
                    plt.close(fig)

                    # tinings
                    timings = [results[i].elapsed for i in idx]
                    fig, ax = plt.subplots()
                    ax.plot(x, [bl.elapsed]*len(x), 'r--', label='ExemplarSVM', linewidth=2)
                    ax.plot(x, timings, 'go-')
                    ax_all_time.plot(x, timings, linestyle='-', marker=next(marker2), label=title)
                    ax.set_xlabel('Number of Windows')
                    ax.set_ylabel('Processing Time in Seconds')
                    ax.legend(('ExemplarSVM', title), loc='lower right')
                    fig.savefig(str(timing_folder / "window_comparison-{}-{}-{}-{}-{}-{}.png".format(clusters,
                                                                                                     parts,
                                                                                                     filtered,
                                                                                                     win_img_ratio,
                                                                                                     query_src,
                                                                                                     nonmax)))
                    plt.close(fig)

                if not x_all:
                    plt.close(fig_all_perf)
                    plt.close(fig_all_time)
                    continue

                x_all = list(sorted(x_all))

                ax_all_perf[0].plot(x_all, [bl.average_precision]*len(x_all), 'r--',
                                    label='ExemplarSVM', linewidth=2)
                ax_all_perf[0].legend(loc='lower center', ncol=2, fontsize='small')
                _, ymax = ax_all_perf[0].get_ylim()
                ax_all_perf[0].set_ylim((None, ymax * 1.1))

                gt = GroundTruth.get()
                gd = gt[img][0]
                bb = gd.bbox
                I = imread(str(gd.I))

                I[np.arange(bb.y_min, bb.y_max), bb.x_min-1, :] = 255, 0, 0
                I[np.arange(bb.y_min, bb.y_max), bb.x_max-1, :] = 255, 0, 0
                I[bb.y_min-1, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
                I[bb.y_max-1, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
                I[np.arange(bb.y_min, bb.y_max), bb.x_min, :] = 255, 0, 0
                I[np.arange(bb.y_min, bb.y_max), bb.x_max, :] = 255, 0, 0
                I[bb.y_min, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
                I[bb.y_max, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0

                ax_all_perf[1].imshow(I)
                w = fig_all_perf.get_figwidth()
                fig_all_perf.set_figwidth(w*2)
                fig_all_perf.savefig(str(perf_folder / "window_comparison-{}.png".format(img)))

                ax_all_time.plot(x_all, [bl.elapsed]*len(x_all), 'r--',
                                 label='ExemplarSVM', linewidth=2)
                ax_all_time.legend(loc='upper left', ncol=2, fontsize='small')
                fig_all_time.savefig(str(timing_folder / "window_comparison-{}.png".format(img)))


def main():
    for database in ('database2', 'database'):
        process_database(database)

if __name__ == '__main__':
    main()

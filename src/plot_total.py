#!/usr/bin/env python3
# encoding: utf-8
import numpy as np
import matplotlib.pyplot as plt
from collections import namedtuple
from scipy.io import loadmat
from pathlib import Path as P
from h5py import File as loadhdf
from xml.etree import ElementTree as ET
from sklearn.metrics import average_precision_score
from sklearn.preprocessing import normalize
from pprint import pprint
from itertools import product, cycle
import sys


ROOT = P(__file__).absolute().parent.parent
ESVM_PATH = ROOT / '..' / 'masato' / 'timo2'
RESULT_PATH = ROOT / 'results'
PASCAL_PATH = ROOT / 'DBs' / 'Pascal' / 'VOC2011'
TIMING_PATH = RESULT_PATH / 'timings'
PERFORMANCE_PATH = RESULT_PATH / 'performance'
Baseline = namedtuple('Baseline', 'elapsed, extract, windows, average_precision, win_type')
GroundData = namedtuple('GroundData', 'fileid, I, positive, bbox, objectid')
BoundingBox = namedtuple('BoundingBox', 'x_min, y_min, x_max, y_max')
Result = namedtuple('Result', 'fileid, score, bbox')
MyLine = namedtuple('MyLine', 'elapsed, extract, windows, average_precision, win_type')
FILES = ('2008_004363', '2009_004882', '2010_005116', '2009_000634', '2010_003701')[:1]
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
    left = max(int(A[0]), int(B[0]))
    right = min(int(A[2]), int(B[2]))
    top = max(int(A[1]), int(B[1]))
    bottom = min(int(A[3]), int(B[3]))

    if left <= right and top <= bottom:
        intersectionArea = (right-left)*(bottom-top)
    else:
        intersectionArea = 0

    left = min(int(A[0]), int(B[0]))
    right = max(int(A[2]), int(B[2]))
    top = min(int(A[1]), int(B[1]))
    bottom = max(int(A[3]), int(B[3]))
    # Compute union
    unionArea = (right-left)*(bottom-top)
    # Compute Pascal measure
    return intersectionArea/unionArea


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


def get_average_precision2(results):
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
    if labels.shape[0] > expected_len:
        print("Removing last", labels.shape[0] - expected_len, "results")
        labels = labels[:expected_len]
        scores = scores[:expected_len]
    #print(scores)
    # variant 1: consider all as match -> bad for esvm
    scores = np.ones(scores.shape, dtype=bool)
    # variant 2: normalize values
    #scores = (scores - scores.min()) / (scores.max() - scores.min())
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
    #print(labels)
    #print(scores)
    #print('#Positive:', labels.sum())
    return average_precision_score(labels, scores)

get_average_precision = get_average_precision2


def get_baseline():
    data = []
    files = tuple(ESVM_IDS[f-1] for f in ESVM_FILES)
    for img in FILES:
        i = files.index(img) + 9
        filename = ESVM_PATH / 'data' / 'imageFiles_database' / '{:03}'.format(i) / 'results' / \
            'exemplar_001' / 'all_detects_sort_highest_score_exempl.mat'

        if not filename.exists():
            continue

        with loadhdf(str(filename)) as mat:
            results = mat['all_detects_sort_highest_score_exempl'].value

        results2 = []
        for i in range(results.shape[1]):
            r = results[(10, 11, 0, 1, 2, 3), i]
            r = Result(ESVM_IDS[int(r[0])-1], r[1], BoundingBox(*(r[2:]-1)))
            results2.append(r)

        avg_precision = get_average_precision(results2)

        mat = loadmat(str(ESVM_PATH / 'results.mat'))

        data.append(Baseline(
                float(mat['elapsed_time']),
                float(mat['extract_time']),
                mat['num_windows'][:, 0].mean(),
                avg_precision,
                None))
    return get_mean(data, 'win_type')[0]


def get_results(clusters, parts, filtered, scale_ranges, win_img_ratio, query_src, fileid):
    #print(fileid)
    mat = loadmat(str(TIMING_PATH / "total-{}-{}-{}-{}-{:.2f}-{}-{}.mat".format(clusters,
                                                                                parts,
                                                                                filtered,
                                                                                scale_ranges,
                                                                                win_img_ratio,
                                                                                query_src,
                                                                                fileid)))
    results = mat['results'][0, :]
    num_windows = mat['num_windows'][0, :]
    elapsed_time = mat['elapsed_time'][0, :]

    mylines = []
    for win_type, (r, nw, elapsed_time1) in enumerate(zip(results, num_windows, elapsed_time)):
        nw = int(nw)
        if nw == 0:
            continue

        #print(win_type, "#Windows:", nw)
        r = r[0, 0][0, :]

        results2 = []
        for r1 in r:
            r1 = Result(r1['curid'][0], r1['score'][0, 0], BoundingBox(*(r1['bbox'][0, :]-1)))
            results2.append(r1)
        #print("#Results:", len(results2))
        avg_precision = get_average_precision(results2)
        #print("Average Precision:", avg_precision)

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


def main():
    bl = get_baseline()
    print("Baseline precision:", bl.average_precision)

    for scale_ranges in (1, 3):
        timing_folder = TIMING_PATH / str(scale_ranges)
        if not timing_folder.exists():
            timing_folder.mkdir()

        perf_folder = PERFORMANCE_PATH / str(scale_ranges)
        if not perf_folder.exists():
            perf_folder.mkdir()

        fig_all_perf, ax_all_perf = plt.subplots()
        ax_all_perf.set_xlabel('Number of Windows')
        ax_all_perf.set_ylabel('Average Precision')
        #ax_all_perf.set_ylim((0, 1.1))
        fig_all_perf.suptitle('50% Bounding Box Overlap Required')
        fig_all_perf.canvas.set_window_title('All Performance')

        fig_all_time, ax_all_time = plt.subplots()
        ax_all_time.set_xlabel('Number of Windows')
        ax_all_time.set_ylabel('Processing Time in Seconds')
        fig_all_time.suptitle('50% Bounding Box Overlap Required')
        fig_all_time.canvas.set_window_title('All Timings')
        x_all = set([])
        marker = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))
        marker2 = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))

        for clusters, parts, filtered, win_img_ratio, query_src in product((512, 1000),
                                                                           (1, 4),
                                                                           ('filtered', 'unfiltered'),
                                                                           (1, 0.75),
                                                                           ('integral', 'raw')):
            img_results = []
            for img in FILES:
                try:
                    img_results += get_results(clusters, parts, filtered, scale_ranges, win_img_ratio, query_src, img)
                except IOError as e:
                    #print("Load error", e)
                    continue
            print("Loaded", len(img_results), "/", len(FILES), "results")
            if not img_results:
                continue
            results = get_mean(img_results, 'win_type')

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
            fig, ax = plt.subplots()
            ax.plot(x, [bl.average_precision]*len(x), 'r--',
                    label='ExemplarSVM', linewidth=2)
            ax.plot(x, precisions, 'go-')
            ax_all_perf.plot(x, precisions, linestyle='-', marker=next(marker), label=title)
            ax.set_xlabel('Number of Windows')
            ax.set_ylabel('Average Precision')
            #ax.set_ylim((0, 1.1))
            ax.legend(('ExemplarSVM', title), loc='lower right')
            fig.suptitle('50% Bounding Box Overlap Required')
            fig.savefig(str(perf_folder / "window_comparison-{}-{}-{}-{}-{}.png".format(clusters,
                                                                                        parts,
                                                                                        filtered,
                                                                                        win_img_ratio,
                                                                                        query_src)))
            plt.close(fig)


            timings = [results[i].elapsed for i in idx]
            fig, ax = plt.subplots()
            ax.plot(x, [bl.elapsed]*len(x), 'r--', label='ExemplarSVM', linewidth=2)
            ax.plot(x, timings, 'go-')
            ax_all_time.plot(x, timings, linestyle='-', marker=next(marker2), label=title)
            ax.set_xlabel('Number of Windows')
            ax.set_ylabel('Processing Time in Seconds')
            ax.legend(('ExemplarSVM', title), loc='lower right')
            fig.savefig(str(timing_folder / "window_comparison-{}-{}-{}-{}-{}.png".format(clusters,
                                                                                          parts,
                                                                                          filtered,
                                                                                          win_img_ratio,
                                                                                          query_src)))
            plt.close(fig)

        if not x_all:
            plt.close(fig_all_perf)
            plt.close(fig_all_time)
            continue

        x_all = list(sorted(x_all))

        ax_all_perf.plot(x_all, [bl.average_precision]*len(x_all), 'r--',
                         label='ExemplarSVM', linewidth=2)
        ax_all_perf.legend(loc='lower center', ncol=2, fontsize='small')
        fig_all_perf.savefig(str(perf_folder / "window_comparison.png"))

        ax_all_time.plot(x_all, [bl.elapsed]*len(x_all), 'r--',
                         label='ExemplarSVM', linewidth=2)
        ax_all_time.legend(loc='upper left', ncol=2, fontsize='small')
        fig_all_time.savefig(str(timing_folder / "window_comparison.png"))
    plt.show()

if __name__ == '__main__':
    main()

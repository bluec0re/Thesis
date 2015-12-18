import logging
import numpy as np
from sklearn.metrics import average_precision_score, auc

from .pascal.groundtruth import GroundTruth, pascal_overlap


log = logging.getLogger(__name__)


def get_average_precision1(results):
    """
    Calc average precision, version 1

    Uses ground truth as labels
    """
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
    """
    Extends/Shrink labels and scores to a given length

    Does currently nothing
    """
    return labels, scores

    if labels.shape[0] > expected_len:
        log.debug("Removing last %d results", labels.shape[0] - expected_len)
        labels = labels[:expected_len]
        scores = scores[:expected_len]

    if labels.shape[0] < expected_len:
        log.debug("Adding %d missing labels", expected_len - labels.shape[0])

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
    """
    Calc average precision, version 1

    Uses matches (bbox overlap >= 50%) as labels
    """
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

    # variant 1: consider all as match -> bad for esvm
    scores = np.ones(scores.shape, dtype=bool)

    # variant 2: normalize values to [0, 1]
    # scores = (scores - scores.min()) / (scores.max() - scores.min())

    [labels, scores] = adjust_vectors(labels, scores, expected_len, gt)

    # print('#Positive:', labels.sum())
    # simple average precision calculation
    # ap = average_precision_score(labels, scores)

    # Consider to a specific recall value
    precisions = np.cumsum(labels) / np.arange(1, labels.shape[0]+1)
    # precisions = np.insert(precisions, 0, [1.0])
    # precisions = np.append(precisions, [0.0])
    recalls = np.cumsum(labels) / expected_len
    # recalls = np.insert(recalls, 0, [0.0])
    # recalls = np.append(recalls, [1])

    # No recall value was given -> find 0.5 ratio
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
    return [ap2, threshold]


get_average_precision = get_average_precision2

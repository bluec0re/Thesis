#!/usr/bin/env python3
# encoding: utf-8
from scipy.io import loadmat
import matplotlib.pyplot as plt
import numpy as np
import os

BASE = os.path.dirname(os.path.abspath(__file__))


LABELS = {
    'naiive': 'Naiive',
    'sparse-kd': 'KD-Tree',
    'sparse-kd2': 'KD-Tree 2',
    'sparse-matlab': 'Sparse',
    'sparse': 'Checkpoints',
    'sparse-sum': 'Sum',
    'sparse-overwrite': 'Overwrite'
}


m = loadmat(BASE + '/database/extract.mat')
if m['combinations'].shape[0] > 5:
    combinations = m['combinations'][5, :, :, :].T.flatten()
else:
    combinations = m['combinations'][0, :, :, :].T.flatten()
combinations = [[e.flatten()[0] for e in c[0, 1:]] for c in combinations]
print(combinations)
if m['combinations'].shape[0] > 5:
    num_windows = m['num_windows'].reshape([24, 6])[:, 5]
else:
    num_windows = m['num_windows'].reshape([24, 1])[:, 0]
i = num_windows > 0
labels = np.array(["{},{:5d}, {}".format(LABELS[c[2]], c[1], c[0]) for c in combinations])[i]
if m['combinations'].shape[0] > 5:
    timings = m['timings'].reshape([24, 6])[i, 5]
else:
    timings = m['timings'].reshape([24, 1])[i, 0]
print(timings)

x = np.arange(timings.shape[0])
i = np.argsort(timings)
timings = timings[i] / 50.0
labels = labels[i]

for l, t in zip(timings, labels):
    print(l, t)

fig, ax = plt.subplots()
#ax.set_yscale('log')
ax.bar(x - 0.5, timings)
plt.xticks(x, labels, rotation='vertical')
plt.xlim([-1, x[-1] + 1])
plt.ylabel('Time to extract in seconds per image')
plt.subplots_adjust(bottom=0.4)
plt.savefig(BASE + '/extract_times.png')
plt.savefig(BASE + '/extract_times.pdf')
plt.show()

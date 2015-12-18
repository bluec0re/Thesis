#!/usr/bin/env python3
# encoding: utf-8
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import loadmat


LABELS = {
    b'naiive': 'Naiive',
    b'sparse-kd': 'KD-Tree',
    b'sparse-kd2': 'KD-Tree 2',
    b'sparse-matlab': 'Sparse',
    b'sparse': 'Checkpoints',
    b'sparse-sum': 'Sum',
    b'sparse-overwrite': 'Overwrite'
}


def autolabel(ax, rects, pos):
    for r in rects:
        h = r.get_height()
        ax.text(r.get_x()+r.get_width()/2, 1.05*h, '%.1f' % h,
                ha=pos, va='bottom')


def loadings():
    m = loadmat('loading.mat')

    labels = np.array(list(s[0][1][0] for s in m['combinations'][0, :]), dtype='S16')
    timings = m['timings'].reshape((7, 2))
    memsizes = m['memsizes'].reshape((7, 2))
    filesizes = m['filesizes'].reshape((7, 2))

    def plot_loading_time(timings):
        fig, ax = plt.subplots()
        t = timings[:, 0]
        rects = ax.bar(np.arange(t.shape[0]) - 0.3, t, 0.25, log=False, color='r', hatch='x')
        t = timings[:, 1]
        rects2 = ax.bar(np.arange(t.shape[0]), t, 0.25, log=False, color='y', hatch='-')

        ax.legend((rects[0], rects2[0]), ('512', '1000'), loc='upper left')

        autolabel(ax, rects, 'right')
        autolabel(ax, rects2, 'left')

        plt.ylabel('Loading time in seconds')
        plt.xticks(np.arange(t.shape[0]), list(LABELS[k] for k in labels), rotation='vertical')
        plt.subplots_adjust(bottom=0.2)

    def plot_size(sizes, label):
        fig, ax = plt.subplots()
        fs = sizes[:, 0]
        rects = ax.bar(np.arange(fs.shape[0]) - 0.3, fs, 0.25, log=False, color='r', hatch='x')
        fs = sizes[:, 1]
        rects2 = ax.bar(np.arange(fs.shape[0]), fs, 0.25, log=False, color='y', hatch='-')

        ax.legend((rects[0], rects2[0]), ('512', '1000'), loc='upper left')

        autolabel(ax, rects, 'right')
        autolabel(ax, rects2, 'left')

        plt.ylabel(label)
        plt.xticks(np.arange(fs.shape[0]), list(LABELS[k] for k in labels), rotation='vertical')
        plt.subplots_adjust(bottom=0.2)

    i = np.argsort(timings[:, 0])
    timings = timings[i, :]
    labels = labels[i]
    memsizes = memsizes.reshape((7,2))[i,:]
    filesizes = filesizes.reshape((7,2))[i,:]

    plot_loading_time(timings)
    plt.savefig('loading_time.pdf')
    plt.savefig('loading_time.png')

    plot_loading_time(timings[:5,:])
    plt.savefig('loading_time_2.pdf')
    plt.savefig('loading_time_2.png')

    plot_size(filesizes / 1024**2, 'Filesize in MB')
    plt.savefig('file_size.pdf')
    plt.savefig('file_size.png')

    plot_size(memsizes / 1024**3, 'Memorysize in GB')
    plt.savefig('mem_size.pdf')
    plt.savefig('mem_size.png')

    plot_size(memsizes[:5,:] / 1024**2, 'Memorysize in MB')
    plt.savefig('mem_size2.pdf')
    plt.savefig('mem_size2.png')

def extract():
    m = loadmat('extract.mat')
    combinations = m['combinations'].reshape((6, 2, 2, 6))
    labels = np.array(list(s[0][3][0] for s in combinations[:, 0, 0, 0]), dtype='S16')
    timings = m['timings'].reshape((6, 2, 2, 6))
    num_windows = m['num_windows'].reshape((6, 2, 2, 6))
    #i = np.argsort(timings[:, 0, 0, 0])
    #timings = timings[i, :, :, :]
    #labels = labels[i]

    #fig, ax = plt.subplots()
    ## 1000 clusters
    #t = timings[:, 0, 0, 0]
    #rects = ax.bar(np.arange(t.shape[0]) - 0.5, t)
    #autolabel(ax, rects, 'center')
    #plt.xticks(np.arange(t.shape[0]), list(LABELS[k] for k in labels), rotation='vertical')
    #plt.ylabel('Extract time in seconds')
    #plt.subplots_adjust(bottom=0.2)
    #plt.show()

    t = timings[0, 0, 0, :] / 50
    w = num_windows[0, 0, 0, :]
    i = np.argsort(w)
    w = w[i]
    t = t[i]
    fig, ax = plt.subplots()
    ax.plot(w, t, 'o-')
    ax.set_xscale('log')
    plt.xlabel('#Windows')
    plt.ylabel('Time to extract in seconds')
    settings = [s[0] for s in combinations[0, 0, 0, 0][0]]
    settings = list(map(lambda x: x[0] if str(x.dtype).startswith('uint') else x, settings))
    title = '{} Parts, {} Clusters, {}'.format(*settings[1:])
    plt.title(title)
    plt.show()

loadings()
#extract()

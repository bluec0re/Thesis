import matplotlib.pyplot as plt
import matplotlib.cm as cmx
import matplotlib.colors as colors
from scipy.misc import imread
import numpy as np
from itertools import cycle

from .config import RESULT_PATH


def get_cmap(N):
    '''Returns a function that maps each index in 0, 1, ... N-1 to a distinct
    RGB color.'''
    color_norm = colors.Normalize(vmin=0, vmax=N)
    scalar_map = cmx.ScalarMappable(norm=color_norm, cmap='hsv')

    def map_index_to_rgb_color(index):
        return scalar_map.to_rgba(index)
    return map_index_to_rgb_color


def plot_versus(database, baselines, timings, precisions, windows):
    combinations = timings.keys() | precisions.keys() | windows.keys()
    imgs = baselines.keys()
    target_dir = RESULT_PATH / "timing_vs_performance" / database
    if not target_dir.exists():
        target_dir.mkdir(parents=True)

    print("#Combinations:", len(combinations))

    for combination in combinations:
        esvmmarkers = cycle(('v', 'x', '+', 'o',))
        markers = cycle(('*', '|', 'D', 's'))
        fig, ax = plt.subplots()
        fig.suptitle(combination)
        fig.canvas.set_window_title(combination)
        ax.set_xlabel('Processing Times in Seconds')
        ax.set_ylabel('Precision')
        cmap = get_cmap(len(imgs))

        for i, img in enumerate(imgs):
            # ESVM
            bl = baselines[img]
            x = bl.elapsed
            y = bl.average_precision
            ax.plot(x, y, marker=next(esvmmarkers), color=cmap(i), label="ESVM {}".format(img))

            # My
            x = timings[combination][img]
            if not x:
                continue
            x = sum(x) / len(x)
            y = precisions[combination][img]
            if not y:
                continue
            y = sum(y) / len(y)
            ax.plot(x, y, marker=next(markers), color=cmap(i), label=img)

        # Shrink current axis by 30%
        box = ax.get_position()
        ax.set_position([box.x0, box.y0, box.width * 0.7, box.height])

        # Put a legend to the right of the current axis
        ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
        fig.savefig(str(target_dir / "{}.png".format(combination)))


def show_image(ax, I, bbs=None):
    I = imread(str(I))

    if bbs:
        for bb in bbs:
            I[np.arange(bb.y_min, bb.y_max), bb.x_min-1, :] = 255, 0, 0
            I[np.arange(bb.y_min, bb.y_max), bb.x_max-1, :] = 255, 0, 0
            I[bb.y_min-1, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
            I[bb.y_max-1, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
            I[np.arange(bb.y_min, bb.y_max), bb.x_min, :] = 255, 0, 0
            I[np.arange(bb.y_min, bb.y_max), bb.x_max, :] = 255, 0, 0
            I[bb.y_min, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0
            I[bb.y_max, np.arange(bb.x_min, bb.x_max), :] = 255, 0, 0

    ax.imshow(I)


def plot(bl, x, y, label, filename, xlabel, ylabel, title=None):
    fig, ax = plt.subplots()
    ax.plot(x, [bl.average_precision]*len(x), 'r--',
            label='ExemplarSVM', linewidth=2)
    ax.plot(x, y, 'go-', label=label)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_ylim((None, max(y + [bl.average_precision]) * 1.1))
    ax.legend(loc='lower right')
    if title:
        fig.suptitle(title)
    fig.savefig(filename)
    plt.close(fig)


def plot_dots(bl, x, y, label, filename, xlabel, ylabel, title=None):
    fig, ax = plt.subplots()
    ax.plot(bl.elapsed, bl.average_precision, '+',
            label='ExemplarSVM', linewidth=2)
    ax.plot(x, y, 'go', label=label)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_ylim((None, max(y + [bl.average_precision]) * 1.1))
    ax.legend(loc='lower right')
    if title:
        fig.suptitle(title)
    fig.savefig(filename)
    plt.close(fig)

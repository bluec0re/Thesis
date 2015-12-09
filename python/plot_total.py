#!/usr/bin/env python3
# encoding: utf-8
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict
# from sklearn.preprocessing import normalize
# from pprint import pprint
from itertools import product, cycle

from thesis.config import FILES, TIMING_PATH, PERFORMANCE_PATH
from thesis.results import get_results
from thesis.esvm import get_baseline
from thesis.drawing import plot, show_image, plot_versus
from thesis.pascal.groundtruth import GroundTruth


def process_database(database):
    """
    Create figures for given database name
    """
    baselines = {}
    timings = defaultdict(lambda: defaultdict(list))
    precisions = defaultdict(lambda: defaultdict(list))
    windows = defaultdict(lambda: defaultdict(list))

    for img in FILES:
        bl = get_baseline(database, img)
        baselines[img] = bl
        print("Baseline precision:", bl.average_precision)

        for nonmax in ('union', 'min'):
            for scale_ranges in (1, 3):
                timing_folder = TIMING_PATH / database / nonmax / str(scale_ranges)
                if not timing_folder.exists():
                    timing_folder.mkdir(parents=True)

                perf_folder = PERFORMANCE_PATH / database / nonmax / str(scale_ranges)
                if not perf_folder.exists():
                    perf_folder.mkdir(parents=True)

                # overall figures
                fig_all_perf, ax_all_perf = plt.subplots(1, 2)
                ax_all_perf[0].set_xlabel('Number of Windows')
                ax_all_perf[0].set_ylabel('Average Precision')
                # ax_all_perf.set_ylim((0, 1.1))
                fig_all_perf.suptitle('Query Image {} - 50% Bounding Box Overlap Required'.format(img))
                fig_all_perf.canvas.set_window_title('All Performance - ' + img)

                fig_all_time, ax_all_time = plt.subplots()
                ax_all_time.set_xlabel('Number of Windows')
                ax_all_time.set_ylabel('Processing Time in Seconds')
                fig_all_time.suptitle('Query Image {} - 50% Bounding Box Overlap Required'.format(img))
                fig_all_time.canvas.set_window_title('All Timings - ' + img)
                x_all = set([])
                marker = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))
                marker2 = cycle(('v', 'x', '+', 'o', '*', '|', 'D', 's'))

                # do cross product of all settings
                combinations = product((512, 1000),
                                       (1, 4),
                                       ('filtered', 'unfiltered'),
                                       (1,),  # (1, 0.75),
                                       ('integral',))  # ('integral', 'raw'))
                for clusters, parts, filtered, win_img_ratio, query_src in combinations:
                    # average all images
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
                        results = get_results(clusters, parts, filtered,
                                              scale_ranges, win_img_ratio,
                                              query_src, img, nonmax, database,
                                              None)
                    except IOError as e:
                        print("Load error", e)
                        continue
                    except ValueError as e:
                        print("#####################", e, "#######################")
                        print(clusters, parts, scale_ranges, nonmax, filtered, win_img_ratio, query_src)
                        continue

                    x = [r.windows for r in results]
                    idx = np.argsort(x)
                    x.sort()
                    x_all |= set(x)

                    title = '{}-{}-{}'.format(clusters, parts, scale_ranges)
                    if win_img_ratio != 1:
                        title += "-{}".format(win_img_ratio)
                    if filtered == 'filtered':
                        title += ', Window Filter'
                    if query_src == 'raw':
                        title += ', Raw'
                    title += ', ' + nonmax
                    print("Graph:", title)

                    figure_name = "window_comparison-{}-{}-{}-{}-{}-{}.png".format(clusters,
                                                                                   parts,
                                                                                   filtered,
                                                                                   win_img_ratio,
                                                                                   query_src,
                                                                                   nonmax)

                    # performance vs #windows
                    y = [results[i].average_precision for i in idx]
                    print(y)
                    plot(bl.average_precision, x, y,
                         title, str(perf_folder / figure_name),
                         'Number of Windows', 'Average Precision',
                         '50% Bounding Box Overlap Required')
                    ax_all_perf[0].plot(x, y,
                                        linestyle='-',
                                        marker=next(marker),
                                        label=title)
                    precisions[title][img] += y

                    # timings vs #windows
                    y = [results[i].elapsed for i in idx]
                    plot(bl.elapsed, x, y,
                         title, str(timing_folder / figure_name),
                         'Number of Windows', 'Processing Time in Seconds',
                         '50% Bounding Box Overlap Required')
                    ax_all_time.plot(x, y,
                                     linestyle='-',
                                     marker=next(marker2),
                                     label=title)
                    timings[title][img] += y

                    # performance vs timings
                    windows[title][img] += x

                if not x_all:
                    plt.close(fig_all_perf)
                    plt.close(fig_all_time)
                    continue

                x_all = list(sorted(x_all))

                ax_all_perf[0].plot(x_all, [bl.average_precision]*len(x_all), 'r--',
                                    label='ExemplarSVM', linewidth=2)
                ax_all_perf[0].legend(loc='upper center',
                                      ncol=2, fontsize='small')
                _, ymax = ax_all_perf[0].get_ylim()
                ax_all_perf[0].set_ylim((None, ymax * 1.1))

                gt = GroundTruth.get()
                gd = gt[img][0]
                bb = gd.bbox
                show_image(ax_all_perf[1], gd.I, [bb])

                w = fig_all_perf.get_figwidth()
                fig_all_perf.set_figwidth(w*2)
                fig_all_perf.savefig(str(perf_folder / "window_comparison-{}.png".format(img)))

                ax_all_time.plot(x_all, [bl.elapsed]*len(x_all), 'r--',
                                 label='ExemplarSVM', linewidth=2)
                ax_all_time.legend(loc='upper left', ncol=2, fontsize='small')
                fig_all_time.savefig(str(timing_folder / "window_comparison-{}.png".format(img)))

                plt.close(fig_all_perf)
                plt.close(fig_all_time)

    # plot time vs precision
    plot_versus(database, baselines, timings, precisions, windows)


def main():
    for database in ('database2', 'database'):
        process_database(database)

if __name__ == '__main__':
    main()

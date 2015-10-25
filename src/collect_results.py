#!/usr/bin/env python2
# encoding: utf-8
# author: Timo Schmid

import sys
import h5py
import glob
import os


def main():
    path = 'results/queries/scaled/*/*/*/*/*/*/*/*/*/*/*/*/*/*/results.mat'
    for result_file in glob.iglob(path):
        with h5py.File(str(result_file), 'r') as f:
            current_results = f['results']
            current_params = f['cleanparams']
            current_time = f['elapsed_time']
            import pdb; pdb.set_trace()
        break

if __name__ == '__main__':
    main()

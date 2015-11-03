Setup
=====

1. Get code dependencies


    git submodule update --init


5. Compile MEX extensions


    cd src/internal/code; make


3. Extract PASCAL VOC2011 Dataset into


    DBs/PASCAL/VOC2011


Demo
====


    addpath('src');
    demo(false);


Using different approaches
--------------------------

Different settings can be either set in the `src/api/get_default_configuration.m` or by setting them in the demo call:


    demo(false, 'naiive_integral_backend', false, 'use_kdtree', true)


Framework Structure
===================


    ├── doc                         Documentation like API or sample callgraph
    ├── python                      Python scripts for plotting + API generation
    ├── src                         Scripts using the framework
    │   ├── api                     Wrapper functions which can be called outside
    │   ├── internal                Internal used functions
    │   │   ├── c                   C extensions
    │   │   ├── scales              Functions to handle different scale ranges
    │   │   └── utils               Utility functions
    │   │       ├── log             Logging Framework
    │   │       └── metrics         Precision/Recall & ROC
    │   └── statistics              Some measure scripts (outdated)
    └── vendors                     Used libraries/scripts from other developers


Editing the File list
---------------------

The images of the database are listed in a file in the `data` folder.
A list contains one image id (PASCAL filename without extension) with a 1 or 0
if a PASCAL class is known (all ones otherwise). The generation of the a database
is done by

    demo(true, 'db_stream_name', <name of the database>, 'stream_max', <maximum allowed total objects in the images>)


Results
-------

A query through the demo function creates a folder chain inside of `results/queries/scaled`.
The names of the folders depend on the selected configuration and provide a distinct
location for different runs.
Each folder contain a `query.jpg` with the query image, the best windows found in the
database and a `results.mat` containing the query results in the form:

    results = {
        struct array with #results entries
             .query_curid  -> The id of the search image
             .curid        -> The id of the file were the window was found
             .img          -> The index of the image in the database
             .patch        -> The index of the window inside the image
             .score        -> The score of the window
             .bbox         -> The bounding box of the window
             .filename     -> The filename of the image
             .num_windows  -> The amount of windows searched inside the image
    }


Tests
-----

Tests can be run by using the `timings` function. It will generate files in the
`results/timings` and `results/performance` directories, depending on the test run.
The `timings('complete')` call does an overall test with time measures and stores
the results of the queries. The produced files `results/timings/total*.mat` contain
the variables

    results         -> The results of the demo function
    elapsed_time    -> The average time required to perform a query
    num_windows     -> The number of windows generated


Internals
---------

The internal data structures are mostly struct arrays. Namely:

    feature
        .all_scales         -> Scale factors used in the feature pyramid
        .curid              -> ID of the image
        .objectid           -> Index of the object
        .feature_type       -> Extracted with a mask or not
        .I_size             -> Size of the input image
        .X                  -> The features itself
        .M                  -> The gradient
        .scales             -> The map between feature and scale
        .bbs                -> Patch bounding boxes
        .window2feature     -> List of sliding windows
        .area               -> Area of which the features were extracted
        .distVec            -> LDA distance vector
        .deletedFeatures    -> Removed features during filtering

    integral
        .I                  -> The integral image itself
        .I_size             -> The size of the full integral image
        .curid              -> The ID of the source image
        .scale_factor       -> The factor of which the integral image was shrinked
        .max_size           -> The maximum size of the patches used inside the integral
        .min_size           -> The minimum size of the patches used inside the integral
        .tree               -> kd-Tree representation
        .scores             -> The codebook entries
        .idx                -> The indices of the codebook entries
        .coords             -> The coordinates of the codebook entries
        .small_tree         -> kd-Tree without the codebook entries

    codebook
        .I                  -> The codebook itself
        .curid              -> The image were the codebook comes from
        .size               -> The size of the window

    cluster
        .centroids                 -> The centroids of the k-means
        .codebookSize              -> The number of clusters/codebook dimensions
        .feature2codebook          -> function to get a codebook from a feature
        .feature2codebookintegral  -> function to get an integral image from a list of features

    svm_model
        .model              -> The underlying implementation
            .SVs            -> Support vectors from libsvm
            .sv_coef        -> Coefficents from libsvm
            .rho            -> Rho from libsvm
        .curid              -> ID of the trained image
        .codebook           -> Used positive codebook
        .cb_size            -> Size of the codebook
        .classify           -> function to score a list of codebooks

function windows_bb = calc_windows(params, w, h, cbw, cbh, I )
%CALC_WINDOWS Calculates the windows wich have to be extracted in a sliding window approach
%
%   Syntax:     windows_bb = calc_windows(params, w, h, cbw, cbh, I )
%
%   Input:
%       params - Configuration struct
%       w - Width of the image
%       h - Height of the image
%       cbw - Smallest width of a window
%       cbh - Smallest height of a window
%       I - Optional test image to produce a intagral.avi file for visualization
%
%   Output:
%       windows_bb - Nx4 matrix of windows ($x_{min}$, $y_{min}$, $x_{max}$, $y_{max}$)

    if ~exist('cbw', 'var')
        cbw = 32;
    end

    if ~exist('cbh', 'var')
        cbh = 32;
    end

    debug = exist('I', 'var');

    if debug
        writerObj = VideoWriter('integral.avi');
        writerObj.FrameRate = 8;
        open(writerObj);
        fig = 1;
    end

    info('Calculating windows...', false);
    tic;

    windows_bb = [];
    for s=0:params.max_window_scales
        scale = 2^s;

        bw = cbw * scale;
        bh = cbh * scale;
        step = params.window_margin;% * scale;
        if params.window_generation_relative_move > 0
            step = round(min([bw bh]) / params.window_generation_relative_move);
        end

        if bw > w * params.max_window_image_ratio || bh > h * params.max_window_image_ratio
            break
        end
        for x=1:step:w
            for y=1:step:h
                bb = [max(x, 1), max(y, 1), min(x + bw, w), min(y + bh, h)];
                if bb(3) > params.min_window_size * bw && bb(4) > params.min_window_size * bh
                    windows_bb = [windows_bb; bb];
                end

                if debug
                    figure(fig);
                    set(fig, 'Visible', 'Off');
                    image(I);
                    drawBboxOverlay(size(I), bb);
                    rectangle('Position', [bb(1:2) (bb(3:4) - bb(1:2))]);
                    writeVideo(writerObj, getframe);
                end
            end
        end
    end
    windows_bb = unique(windows_bb, 'rows');
    sec = toc;
    succ('DONE in %f sec. %d total windows', sec, size(windows_bb, 1), false, true);


    if debug
        close(writerObj);
        quit;
    end
end

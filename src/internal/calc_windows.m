function [ windows_bb ] = calc_windows( w, h, cbw, cbh, I )
%CALCWINDOWS Summary of this function goes here
%   Detailed explanation goes here

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

    fprintf('Calculating windows...');
    tic;

    windows_bb = [];
    for s=0:10
        scale = 2^s;

        bw = cbw * scale;
        bh = cbh * scale;
        step = 10;
        if bw > w || bh > h
            break
        end
        for x=1:step:w
            for y=1:step:h
                bb = [max(x, 1), max(y, 1), min(x + bw, w), min(y + bh, h)];
                windows_bb = [windows_bb; bb];
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
    sec = toc;
    fprintf('DONE in %f sec\n', sec);


    if debug
        close(writerObj);
        quit;
    end
end
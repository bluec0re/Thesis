function make_sound( finished )
%MAKE_SOUND Summary of this function goes here
%   Detailed explanation goes here

    if finished
        load handel;
    else
        load gong;
    end
    sound(y, Fs);
end


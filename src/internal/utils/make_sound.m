function make_sound( finished )
%MAKE_SOUND Plays a soundtrack to get attention
%   Could be used to signal the end of a computation or the presence of an error
%
%   Syntax:     make_sound( finished )
%
%   Input:
%       finished - Boolean, specifies if a gong (false) or a handel (true) should be played

    if finished
        load handel;
    else
        load gong;
    end
    sound(y, Fs);
end

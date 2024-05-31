function [res1,res2] = switchOnOff(val)
% switchOnOff swith on/off states
%   Use for octave/matlab compatibility in graph
%  Input:
%   val - on/off string character
%  Output:
%   res1 - inverse off/on character
%   res2 - logical value
    switch val
        case 'on'
            res1='off';
            res2=false;
        case 'off'
            res1='on';
            res2=true;
        otherwise
            res1='off';
            res2=false;
    end
end
function [newState, flag] = toggleState(currentState)
%toggleState - This function takes the current state as input and returns the opposite state 
%   If the input is 'on', it returns 'off' and false; if it is 'off', it returns 'on' and true,
%   otherwise it returns 'off' and false.
%   It is use for Matlab/Octave compatibility in the graphic packagge
%   
%   Usage
%     [newState, flag] = toggleState(currentState)
%
%   Input Arguments
%     currentState - on/off value string
%
%   Output Arguments
%     newState - the oposite value off/on
%     flag - true/false logical value
%
    switch currentState
        case 'on'
            newState='off';
            flag=false;
        case 'off'
            newState='on';
            flag=true;
        otherwise
            newState='off';
            flag=false;
    end
end
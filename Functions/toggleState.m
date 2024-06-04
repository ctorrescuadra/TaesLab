function [newState, flag] = toggleState(currentState)
% This function takes the current state as input and returns the opposite state, 
% along with a corresponding boolean value.
% If the input is 'on', it returns 'off' and false; if it is 'off', it returns 'on' and true,
% otherwise it returns 'off' and false.
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
function res = isValid(obj)
%isValid - Check if it is a valid TaesLab object.
%
%   Syntax:
%     res = isValid(obj)
%
%   Input Argument:
%     obj   - cTaesLab object
%  
%   Output Argument:
%     res - true | false
%  
    res = isa(obj,'cTaesLab') && obj.status;
end
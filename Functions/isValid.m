function res = isValid(obj)
%isValid - Check if it is a valid TaesLab object.
%
%   Syntax
%     res = isValid(obj)
%
%   Input Argument:
%     obj   - cTaesLab object
%  
%   Output Argument:
%     res - true | false
%
%   Example
%     res = isValid(obj); %return true if obj is a valid cTaesLab object
%
    %Check input arguments
    res=false;
    if nargin~=1, return; end
    res = isa(obj,'cTaesLab') && obj.status;
end
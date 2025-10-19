function res = isValid(obj)
%isValid - Check if 'obj' is a valid TaesLab object.
%
%   Syntax:
%     res = isValid(obj)
%
%   Input Arguments:
%     obj   - cTaesLab object
%  
%   Output Arguments:
%     res - true | false
%
%   Example:
%     res = isValid(obj); %return true if obj is a valid cTaesLab object
%    
    res=false;
    %Check input arguments
    if nargin~=1, return; end
    res = isa(obj,'cTaesLab') && obj.status;
end
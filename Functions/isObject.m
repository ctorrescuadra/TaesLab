function res=isObject(obj,class)
%isObject - Check is a valid cTaesLab object belong to a specific class.
%
%   Syntax:
%     res = isObject(obj,class)
%
%   Input Arguments:
%     obj   - cTaesLab object
%     class - name of the class (char array)
%  
%   Output Arguments:
%     res - true | false
%
%   Example:
%     res = isObject(obj, 'cDataModel'); %return true if obj is a valid cDataModel object
%
    res=false;
    % Check Input
    if nargin~=2 || ~ischar(class) || isempty(class)
        return
    end
    res = isValid(obj) && isa(obj,class);
end
function res=isFilename(filename)
%isFilename - Check if file name is valid for read/write mode.
%   The file name is valid if it matches the pattern defined in cType.FILE_PATTERN.
%   
%   Syntax:
%     res = isFilename(filename)
%
%   Input Arguments:
%     filename - Name of the file to check
%       char array | string
%
%   Output Arguments:
%     res - Logical check
%       true | false
%         The file name is valid if it matches the pattern defined in cType.FILE_PATTERN.
%   Example:
%     res = isFilename('data.txt') % returns true   
%     res = isFilename('invalid/file:name') % returns false
%
    res=false;
    % Check Input
    if nargin~=1 || isempty(filename) || ~(ischar(filename) || isstring(filename))
        return
    end
    filename=char(filename); % Convert to char array if it is a string
    % Check if the filename matches the pattern
    [~,name,ext]=fileparts(filename);
    if regexp(strcat(name,ext),cType.FILE_PATTERN,'once')
        res=true;
    end
end
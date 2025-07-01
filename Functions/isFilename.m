function res=isFilename(filename)
%isFilename - Check if file name is valid for read/write mode.
%   
%   Syntax
%     res = isFilename(filename)
%
%   Input Argument
%     filename - Name of the file to check
%       char array | string
%
%   Output Argument
%     res - Logical check
%       true | false
%      
    res=false;
    if ~ischar(filename) && ~isstring(filename)
        return
    end
    [~,name,ext]=fileparts(filename);
    if regexp(strcat(name,ext),cType.FILE_PATTERN,'once')
        res=true;
    end
end
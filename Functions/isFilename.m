function res=isFilename(fname)
% Check if file name is valid for write mode 
    res=false;
    if ~ischar(fname) && ~isstring(fname)
        return
    end
    [~,name,ext]=fileparts(fname);
    if regexp(strcat(name,ext),cType.FILE_PATTERN,'once')
        res=true;
    end
end
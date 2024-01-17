function log=exportLaTeX(tbl,filename)
% exportLaTeX generates the LaTex table code file of cTable object
% USAGE:
%   exportLaTeX(tbl, filename)
% INPUT:
%   tbl - cTable object to convert
%   filename - Name of the file.
% 
% See also cTable
%
    % Check Inputs
    log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~ischar(filename)) || ~isa(tbl,'cTable')
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileWrite(filename)
        log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.LaTeX)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    obj=cBuildLaTeX(tbl);
    log=obj.exportTable(filename);
end
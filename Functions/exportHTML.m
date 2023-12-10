function log=exportHTML(tbl,filename)
% Save a table as HTML file
% USAGE:
%   log=exportHTML(tbl, filename)
% INPUT:
%   tbl - cTable to save
%   filename - Name of the file
% OUTPUT:
%   log - cStatusLogger with the messages
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
    if ~cType.checkFileExt(filename,cType.FileExt.HTML)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    % Get the HTML file
    html=cBuildHTML(tbl);
    log=html.saveTable(filename);
    if isValid(log)
        log.messageLog(cType.INFO,'File %s has been saved',filename)
    end
end
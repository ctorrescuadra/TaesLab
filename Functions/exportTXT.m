function log=exportTXT(tbl,filename)
% Save a table as text file
% USAGE:
%   log=exportTXT(tbl, filename)
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
    if ~cType.checkFileExt(filename,cType.FileExt.TXT)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    % Save the file
    try
        fId = fopen (filename, 'wt');
        printTable(tbl,fId)
        fclose(fId);
    catch err
        log.messageLog(cType.ERROR,err.message)
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
    end
    if isValid(log)
        log.messageLog(cType.INFO,'File %s has been saved',filename)
    end
end
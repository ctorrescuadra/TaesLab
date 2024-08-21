function log=exportMAT(obj,filename)
%exportMAT - Save a TaesLab object as MAT file
%   Internal usage in cDataModel, cResultInfo and cTable
%
%   Syntax
%     log=exportMAT(obj, filename)
%
%   Input Arguments
%     obj - cStatusLogger object to save
%     filename - MAT file name
%       char array | string
%
%   Output Arguments
%     log - cStatusLogger containing the status of the save and error messages
%
    log=cStatusLogger();
    if (nargin~=2) || (~isFilename(filename))
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~isa(obj,'cStatusLogger') || ~isValid(obj)
        log.messageLog(cType.ERROR,'Invalid object to save');
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.MAT)
        obj.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    try
	    save(filename,'obj');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
    end
end
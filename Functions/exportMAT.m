function log=exportMAT(obj,filename)
%exportMAT - Save a cTaesLab object as MAT file
%
%  Syntax
%    log=exportMAT(obj, filename)
%
%  Input Arguments
%    obj - cTaesLab object to save
%    filename - MAT file name
%      char array | string
%
%  Output Arguments
%    log - cMessageLogger containing the status of the save and error messages
%
%  See also cDataModel, cResultInfo, cTable
%
    log=cMessageLogger();
    if (nargin~=2) || (~isFilename(filename))
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.MAT)
        log.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
        return
    end
    if ~isValid(obj)
        log.messageLog(cType.ERROR,'Invalid object to save');
        return
    end
    try
	    save(filename,'obj');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
    end
end
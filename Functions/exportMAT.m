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
        log.messageLog(cType.ERROR,cMessages.InvalidInputArgument);
        return
    end
    if ~cType.checkFileExt(filename,cType.FileExt.MAT)
        log.messageLog(cType.ERROR,cMessages.InvalidFileExt,filename)
        return
    end
    if ~isValid(obj)
        log.messageLog(cType.ERROR,cMessages.InvalidObject);
        return
    end
    try
	    save(filename,'obj');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
    end
end
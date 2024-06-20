function log=exportMAT(obj,filename)
% exportMAT save a TaesLab object as MAT file
%   USAGE:
%       log=exportMAT(obj, filename)
%   INPUT:
%       obj - cStatusLogger object to save
%       filename - MAT file name
%   OUTPUT:
%       log - cStatusLogger containing the status of the save and error messages
%
    log=cStatusLogger(cType.VALID);
    if (nargin~=2) || (~isFilename(filename))
        log.messageLog(cType.ERROR,'Invalid input arguments');
        return
    end
    if ~isa(obj,'cTaesLab') || ~isValid(obj)
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
function log=exportMAT(obj,filename)
%exportMAT - Save a cTaesLab object as MAT file.
%   This function is used by SaveResults and SaveTable 
%
%   Syntax:
%     log=exportMAT(obj, filename)
%
%   Input Arguments:
%     obj - cTaesLab object to save
%     filename - MAT file name
%       char array | string
%
%   Output Arguments:
%     log - cMessageLogger containing the status of the save and error messages
%
%   Example:
%     log=exportMAT(obj, 'results.mat');
%
%   See also importMAT
%
    log=cMessageLogger();
    % Check input arguments
    if nargin~=2 || ~isObject(obj,'cTaesLab') || ... 
        ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.MAT)
        log.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end   
    if isOctave
        log.messageLog(cType.ERROR,cMessages.NoSaveFiles,'MAT');
		return
    end
    % Save the object
    try
	    save(filename,'obj');
    catch err
        log.messageLog(cType.ERROR,err.message);
        log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
    end
end
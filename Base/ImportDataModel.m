function obj = ImportDataModel(filename)
%ImportDataModel - Get a cDataModel object from a previous saved MAT file.
%
%   Syntax:
%     obj=ImportDataModel(matfile)
%
%   Input Arguments:
%     filename - Existing MAT file containing a TaesLab object
%       char array | string
%
%   Output Arguments:
%     obj - cDataModel object
%
%	Note: Use printLogger(obj) to display the status of the import and error messages
%
%   Example:
%	  dataModel = ImportDataModel('myDataModel.mat');
%
    obj=cTaesLab(cType.INVALID);
	% Check input arguments
    if isOctave
        obj.printError(cMessages.NoReadFiles,'MAT');
		return
    end
    if (nargin~=1)
        obj.printError(cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.MAT)
        obj.printError(cMessages.InvalidInputFile,filename);
        return
    end
	if ~exist(filename,'file')
		obj.printError(cMessages.FileNotFound,filename);
		return
	end
    % Load MAT file
	try
        S=load(filename);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.printError(err.message)
		obj.printError(cMessages.FileNotRead,filename);
	end
    % Check if it is a valid Data Model
	if isObject(var,'cDataModel')
        obj=var;
        obj.printInfo(cMessages.ValidDataModel,obj.ModelName);
	else
		obj.printError(cMessages.NoDataModel);
	end
end
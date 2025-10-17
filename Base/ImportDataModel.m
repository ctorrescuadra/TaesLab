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
%	   	obj.printLogger cdisplay the status of the import and error messages
%
%   Example:
%	 dataModel = ImportDataModel('myDataModel.mat');
%
    obj=cMessageLogger(cType.INVALID);
	% Check input arguments
    if isOctave
        obj.messageLog(cType.ERROR,cMessages.NoReadFiles,'MAT');
		return
    end
    if (nargin~=1) || ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.MAT)
        obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    % Load and check the model
	try
        S=load(filename);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.messageLog(cType.ERROR,err.message)
		obj.messageLog(cType.ERROR,cMessages.FileNotRead,filename);
	end
	if isObject(var,'cDataModel')
        obj=var;
	else
		obj.messageLog(cType.ERROR,cMessages.NoDataModel);
	end
end
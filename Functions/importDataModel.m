function obj = importDataModel(filename)
%importDataModel - get a cDataModel object from a previous saved MAT file
%
%   Syntax
%     obj=importDataModel(matfile)
%
%   Input Argument
%     filename - Existing MAT file containing a TaesLab object
%       char array | string
%
%   Output Argument
%     obj - cDataModel object
%
    obj=cMessageLogger();
	% Check input arguments
    if isOctave
        obj.messageLog(cType.ERROR,cMessages.NoReadFiles,'MAT');
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
		return
	end
	if isValid(var)
        obj=var;
	else
		obj.messageLog(cType.ERROR,cMessages.InvalidDataModelFile,filename);
	end
end
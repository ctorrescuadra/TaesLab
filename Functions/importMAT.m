function obj = importMAT(filename)
%importMAT - Create a cTaesLab object from a previous saved MAT file.
%   Files can be created using exportMAT function
%
%   Syntax:
%     obj=importMAT(matfile)
%
%   Input Arguments:
%     filename - Existing MAT file containing a TaesLab object
%       char array | string
%
%   Output Arguments:
%     obj - cTaesLab object containing the data from the MAT file		
%
%   See also exportMAT
%
%   Example:
%     obj = importMAT('data.mat')		
%
    obj=cMessageLogger();
	% Check input
    if isOctave
        obj.printError(cMessages.NoReadFiles,'MAT');
		return
    end
	if (nargin~=1) || ~isFilename(filename) || ~cType.checkFileExt(filename,cType.FileExt.MAT)
		obj.printError(cMessages.InvalidArgument,cMessages.ShowHelp);
		return
	end
    % Load and check the model
	try
        S=load(filename);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.printError(err.message)
		obj.printError(cMessages.FileNotRead,filename);
		return
	end
	if isValid(var)
        obj=var;
	else
		obj.printError(cMessages.InvalidMatFileObject,class(obj),filename);
	end
end
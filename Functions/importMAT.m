function obj = importMAT(filename)
%importMAT create a cTaesLab object from a previous saved MAT file
%  Files can be created using exportMAT function
%
%  Syntax
%    obj=importMAT(matfile)
%
%  Input Argument
%    filename - Existing MAT file containing a TaesLab object
%      char array | string
%
%  Output Argument
%    obj - cTaesLab object
%
%  See also exportMAT
%
    obj=cMessageLogger();
	% Check input arguments
    if isOctave
        obj.printError(cMessages.NoReadFiles,'MAT');
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
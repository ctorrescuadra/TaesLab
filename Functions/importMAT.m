function obj = importMAT(filename)
%importMAT - Create a cTaesLab object from a previous saved MAT file
%
%   Syntax
%     obj=importMAT(matfile)
%
%	Input Argument
%     filename - Existing MAT file containing a TaesLab object
%       char array | string
%
%  	Output Argument
%   	obj - cTaesLab object
%
    obj=cMessageLogger();
	% Check input arguments
    if isOctave
        obj.messageLog(cType.ERROR,'Read MAT files is not yet implemented for Octave');
		return
    end
    % Load and check the model
	try
        S=load(filename);
		f=fieldnames(S);
		var=S.(f{1});
	catch err
		obj.messageLog(cType.ERROR,err.message)
		obj.messageLog(cType.ERROR,'Error reading file %s',filename);
		return
	end
	if isValid(var)
        obj=var;
		obj.clearLogger;
	else
		obj.messageLog(cType.ERROR,'Invalid MAT model data file %s',filename);
	end
end
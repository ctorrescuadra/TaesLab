function obj = importMAT(filename)
% importMAT creates a TaesLab object from a previous saved MAT file
%   USAGE:
%       obj=importMAT(matfile)
%	INPUT:
%		filename - Existing MAT file containing a TaesLab object
%  	OUTPUT:
%   	obj - cTaesLab object
%
    obj=cStatusLogger;
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
	if isa(var,'cTaesLab') && isValid(var)
        obj=var;
		obj.clearLogger;
	else
		obj.messageLog(cType.ERROR,'Invalid MAT model file %s',filename);
	end
end